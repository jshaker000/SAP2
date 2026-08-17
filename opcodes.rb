# opcodes.rb
#
# Single source of truth for the SAP2 instruction set.
#
#   * assembler.rb requires this file directly to build its OPS table.
#   * gen_decoder.rb requires this file to render Instruction_Decoder.v.erb
#     into Instruction_Decoder.v.
#
# Every instruction is described once, either as a `template:` (expanded
# below into concrete per-step control-word lists AND a doc string built
# from the template's own parameters) or as raw `steps:` + `desc:` for the
# handful of instructions that are genuinely one-off (fetch/jump/HALT style
# control flow).
#
# OPCODE_TABLE is an ARRAY, not a hash keyed by opcode number: an
# instruction's opcode is simply its index in this array. That means two
# instructions literally cannot collide on the same opcode -- there's no
# hex number to typo or duplicate. The trade-off is that reordering or
# inserting a row renumbers everything after it, so HALT (traditionally
# 0xffff, deliberately far from everything else) just lands whatever index
# it lands at instead. That's fine: nothing in this codebase hardcodes
# opcode *values* anywhere except here, so as long as the assembler and
# decoder are generated from this same array (which they are), the actual
# numbers are an implementation detail.
#
# Step 0 and step 1 are the universal instruction fetch and are emitted
# by the generator itself, not listed per-opcode:
#   step 0: MI CO         (memory_address <= PC)
#   step 1: RO II CE      (instruction <= RAM[memory_address], PC <= PC+1)
# validate_opcode_table! (bottom of this file) enforces that no instruction
# below uses step 0, step 1, or a step number >= MAX_STEPS.

# Must match the INSTRUCTION_STEPS parameter default in Top.v /
# Instruction_Decoder.v -- there's no automated link between the two, this
# is just the Ruby-side half of that contract.
MAX_STEPS = 32

# Canonical register ordering, reused by every loop below so that e.g. the
# MOV family and the PUSH/POP family enumerate registers in the same order
# a reader would expect.
REGS = %i[A T B C].freeze
REGS_NO_T = REGS.filter { |x| x != :T }

# Maps a logical operand ("A", "B", "C", "T", the memory-address register,
# or the program counter) to the control line that puts it *onto* or
# *takes it off* the bus. This is what lets PUSH/POP/OUT/MOV all share one
# template even though PC and the memory-address register don't have their
# own dedicated in/out mnemonics the way A/B/C/T do.
REG_OUT = { A: :ARO, T: :TRO, B: :BRO, C: :CRO, MA: :MO, PC: :CO }.freeze
REG_IN  = { A: :ARI, T: :TRI, B: :BRI, C: :CRI, MA: :MI          }.freeze

# The five two-operand ALU ops, in the order the *I and B/C variants are
# enumerated below.
ALU_OPS = %i[ADD SUB AND OR XOR].freeze

# Short English verb for each ALU op, used to build alu_immediate/alu_reg
# doc strings ("add A to B, storing into T") without repeating it at
# every call site.
ALU_VERB = { ADD: 'add A to', SUB: 'subtract A by', AND: 'and A with',
             OR: 'or A with', XOR: 'xor A with' }.freeze

# Full doc string per unary ALU op -- these aren't a single reusable verb
# (shift vs. rotate vs. negate all read differently), so they're spelled
# out once here instead of once per opcode table row. Insertion order here
# is also the opcode order (see OPCODE_TABLE below), matching the original
# SL, SR, ASR, ROL, ROR, ROLC, RORC, INV, NEG, ABS, CHK sequence.
ALU_UNARY_DESC = {
  SL:   'shift A left 1 bit, storing in T. MSB is discarded',
  SR:   'shift A right 1 bit, storing in T. LSB is discarded',
  ASR:  'arithmetic shift A right 1 bit (preserves sign), storing in T',
  ROL:  'rotate A left 1 bit, storing in T',
  ROR:  'rotate A right 1 bit, storing in T',
  ROLC: 'rotate A left through carry 1 bit, storing in T',
  RORC: 'rotate A right through carry 1 bit, storing in T',
  INV:  'invert A (flip all bits), storing in T',
  NEG:  "negate A (two's complement), storing in T",
  ABS:  'store |A| in T, updating flags',
  CHK:  'store A in T, updating flags (good to check for 0)'
}.freeze

FETCH_NEXT_RAM_AND_UPDATE_COUNTER = %i[MI RE CO CE]

module Templates
  module_function

  # step2: MAR <= PC (addr of operand word), PC++
  # step3: dest <= RAM[MAR]  (i.e. the operand word's own contents)
  def load_direct(dest:)
    { argument: true,
      desc: "load #{dest} from RAM[addr]. addr is the next word in ram",
      steps: {
        2 => FETCH_NEXT_RAM_AND_UPDATE_COUNTER,
        3 => [:RO, REG_IN.fetch(dest)]
      } }
  end

  # step2: MAR <= PC (addr of operand word), PC++
  # step3: RAM[MAR] <= src   (writes into the operand word's own slot)
  def store_direct(src:)
    { argument: true,
      desc: "store #{src} into RAM[addr]. addr is the next word in ram",
      steps: {
        2 => %i[MI CO CE],
        3 => [:RI, REG_OUT.fetch(src)]
      } }
  end

  # step2: MAR <= T (T already holds a target address, e.g. from LDIA/ADDI)
  # step3: dest <= RAM[MAR]
  def load_indirect_t(dest:)
    { argument: false,
      desc: "load #{dest} from RAM[T] (indirect through T)",
      steps: {
        2 => %i[MI RE TRO],
        3 => [:RO, REG_IN.fetch(dest)]
      } }
  end

  def store_indirect_t(src:)
    { argument: false,
      desc: "store #{src} into RAM[T] (indirect through T)",
      steps: {
        2 => %i[MI TRO],
        3 => [:RI, REG_OUT.fetch(src)]
      } }
  end

  # single-step register-to-register move
  def move(from:, to:)
    { argument: false,
      desc: "put #{from} in #{to}",
      steps: { 2 => [REG_OUT.fetch(from), REG_IN.fetch(to)] } }
  end

  # SPU + whatever puts `src` on the bus. Covers PUSHA/T/B/C as well as
  # PUSHPC (src: :PC) and PUSHMA (src: :MA) -- they were only "special
  # cases" before because there was no shared register->control-line map.
  def push(src:)
    { argument: false,
      desc: "push #{src} onto the stack",
      steps: { 2 => [:SPU, REG_OUT.fetch(src)] } }
  end

  # SPO + SO (stack out onto the bus) + whatever latches it into `dest`.
  # Covers POPMA (dest: :MA) the same way. POPPC is NOT this template --
  # popping into the program counter needs the jump control line and an
  # extra cycle to account for the pushed return address landing after a
  # JMP, so it's defined with raw `steps:` below.
  def pop(dest:)
    { argument: false,
      desc: "pop the stack into #{dest}",
      steps: { 2 => [:SPO, :SO, REG_IN.fetch(dest)] } }
  end

  def out(src:)
    { argument: false,
      desc: "output #{src}",
      steps: { 2 => [REG_OUT.fetch(src), :OI] } }
  end

  # step2: MAR <= PC (addr of the immediate word), PC++
  # step3: dest <= RAM[MAR]   (the literal / resolved address itself)
  def load_immediate(dest:)
    d = load_direct(dest: dest)
    d.merge(desc: "load literal/resolved-address operand directly into #{dest}")
  end

  # step2: MAR <= PC, PC++
  # step3: T <= RAM[MAR]              (fetch the immediate operand into T)
  # step4: T <= ALU(A op T), latch flags
  def alu_immediate(op:)
    { argument: true,
      desc: "#{ALU_VERB.fetch(op)} data, store into T. data is next word of ram",
      steps: {
        2 => FETCH_NEXT_RAM_AND_UPDATE_COUNTER,
        3 => [:RO, :TRI],
        4 => [:EO, op, :TRI, :EL]
      } }
  end

  # step2: T <= reg
  # step3: T <= ALU(A op T), latch flags
  def alu_reg(op:, reg:)
    { argument: false,
      desc: "#{ALU_VERB.fetch(op)} #{reg}, storing into T",
      steps: {
        2 => [REG_OUT.fetch(reg), :TRI],
        3 => [:EO, op, :TRI, :EL]
      } }
  end

  # step2: T <= ALU(op, A), latch flags   (unary: shifts, rotates, INV/NEG/ABS/CHK)
  def alu_unary(op:)
    { argument: false,
      desc: ALU_UNARY_DESC.fetch(op),
      steps: { 2 => [:EO, op, :TRI, :EL] } }
  end

  # step2: MAR <= PC, PC++, and if the flag is NOT set, ADV right here
  #        (skip the jump -- just consume the address operand)
  # step3: J RO   (only reached if the flag was set)
  def conditional_jump(flag:)
    { argument: true,
      desc: "jump to RAM[addr] if #{flag} flag is set. addr is the next word of RAM",
      steps: {
        2 => { ctrl: FETCH_NEXT_RAM_AND_UPDATE_COUNTER, skip_unless: flag },
        3 => %i[J RO]
      } }
  end
end

# Builds one OPCODE_TABLE row. Just a thin wrapper so the loops below read
# as `entry(:NAME, template: ..., ...)` instead of repeating `{ name: ... }`
# hash syntax everywhere.
def entry(name, **kwargs)
  { name: name }.merge(kwargs)
end

# `steps:` step numbers map to either:
#   - an Array of control-line symbols (:ADV is appended automatically to
#     the highest-numbered step, unless `no_adv: true` is set on the entry)
#   - a Hash `{ ctrl: [...], skip_unless: :zero|:carry|:odd }`, meaning:
#     assert `ctrl`, and OR in :ADV *unless* the named ALU flag is set --
#     i.e. this step is the exit ramp for the "condition false" case.
#
# `template:` entries are expanded by expand_entry (below) using the
# Templates module above, which supplies both `steps:` and `desc:`.
# `desc:` on a table row is only needed for raw (non-templated) entries,
# or on the rare occasion you want to override what a template generated.
# Either way, the rendered comment is always "NAME - <desc>" -- the name
# itself is never repeated in the description text.
#
# There is deliberately no `opcode:` field anywhere below -- an
# instruction's opcode is its index in this array. See the module comment
# at the top of this file for why.

OPCODE_TABLE = [
  # NOP gets no dedicated `i_instruction ==` branch in the decoder -- any
  # opcode that isn't otherwise defined falls through to this behavior as
  # the implicit default case. It has to be index 0 for that reason.
  entry(:NOP, argument: false, steps: { 2 => %i[ADV] },
        desc: 'do nothing and just advance counter'),

  # NOTE: LDx/STx (direct load/store) use the `load_direct`/`store_direct`
  # templates, which only fetch/write the OPERAND WORD itself -- they do
  # not dereference it as an address the way their names imply. That makes
  # them behave exactly like LDIx (see load_immediate below), and makes
  # STx write back into its own operand slot rather than into the target
  # address. This is flagged, not fixed, here -- see the LDA/STA
  # discussion before changing it, since fixing it means adding a real 3rd
  # step (re-latch MAR from the fetched address, then read again).
  #
  # LD has no LDT variant (T isn't a valid direct-load destination in this
  # ISA -- "LDT..." is reserved for the indirect-through-T family below),
  # but ST does have STT, hence the different register lists here.
  *REGS_NO_T.map { |r| entry(:"LD#{r}", template: :load_direct, dest: r) },
  *REGS.map      { |r| entry(:"ST#{r}", template: :store_direct, src: r) },

  *REGS_NO_T.map { |r| entry(:"LDT#{r}", template: :load_indirect_t, dest: r) },
  *REGS_NO_T.map { |r| entry(:"STT#{r}", template: :store_indirect_t, src: r) },

  # Every (from, to) pair of distinct registers: MOVAT, MOVAB, MOVAC,
  # MOVTA, MOVTB, MOVTC, MOVBA, ...
  *REGS.flat_map do |from|
    (REGS - [from]).map { |to| entry(:"MOV#{from}#{to}", template: :move, from: from, to: to) }
  end,

  # PUSHA, POPA, PUSHT, POPT, PUSHB, POPB, PUSHC, POPC
  *REGS.flat_map { |r| [entry(:"PUSH#{r}", template: :push, src: r), entry(:"POP#{r}", template: :pop, dest: r)] },

  entry(:PUSHPC, template: :push, src: :PC),

  # Popping into PC needs the jump control line (not a normal register-in
  # bit) and, per the original design, PC is advanced twice afterwards to
  # skip past the JMP that presumably follows the matching PUSHPC -- so
  # this stays a raw, hand-specified sequence rather than the pop template.
  entry(:POPPC, argument: false,
        desc: 'pop the stack into PC. we increment the counter 2 times to get ' \
              'past the JMP instruction we presumably did just after PUSHPC',
        steps: { 2 => %i[SPO SO J], 3 => %i[CE], 4 => %i[CE] }),

  entry(:PUSHMA, template: :push, src: :MA),
  entry(:POPMA,  template: :pop,  dest: :MA),

  *REGS.map { |r| entry(:"OUT#{r}", template: :out, src: r) },

  *REGS_NO_T.map { |r| entry(:"LDI#{r}", template: :load_immediate, dest: r) },

  entry(:JMP, argument: true, desc: 'jump to RAM[addr]. addr is the next word of RAM',
        steps: { 2 => FETCH_NEXT_RAM_AND_UPDATE_COUNTER, 3 => %i[J RO] }),
  entry(:JIZ, template: :conditional_jump, flag: :zero),
  entry(:JIC, template: :conditional_jump, flag: :carry),
  entry(:JIO, template: :conditional_jump, flag: :odd),

  *ALU_OPS.map { |op| entry(:"#{op}I", template: :alu_immediate, op: op) },

  *%i[B C].flat_map { |reg| ALU_OPS.map { |op| entry(:"#{op}#{reg}", template: :alu_reg, op: op, reg: reg) } },

  *ALU_UNARY_DESC.each_key.map { |op| entry(op, template: :alu_unary, op: op) },

  entry(:HALT, argument: false, no_adv: true, desc: 'halt the program', steps: { 2 => %i[HLT] })
].freeze

# Expands one OPCODE_TABLE row (template or raw) into
#   { name:, opcode:, argument:, desc:, steps: { n => { ctrl:, skip_unless: } } }
# with :ADV automatically appended to the last step, unless no_adv: true.
# `desc:` on the table row always wins over what a template generated --
# that's the override escape hatch for the rare exception (e.g. POPPC).
def expand_entry(row, opcode)
  base =
    if row[:template]
      kwargs = row.reject { |k, _| %i[name template desc no_adv].include?(k) }
      Templates.public_send(row[:template], **kwargs)
    else
      { argument: row.fetch(:argument), steps: row.fetch(:steps) }
    end

  steps = base[:steps].each_with_object({}) do |(n, v), h|
    h[n] = v.is_a?(Hash) ? { ctrl: v.fetch(:ctrl), skip_unless: v[:skip_unless] } : { ctrl: v, skip_unless: nil }
  end

  unless row[:no_adv] || steps.empty?
    last = steps.keys.max
    steps[last][:ctrl] += [:ADV] unless steps[last][:ctrl].include?(:ADV)
  end

  desc = row[:desc] || base[:desc] || row.fetch(:name).to_s

  { name: row.fetch(:name), opcode: opcode, argument: base.fetch(:argument),
    desc: "#{row.fetch(:name)} - #{desc}", steps: steps }
end

# Memoized: `table` (OPCODE_TABLE) never changes at runtime, no reason to
# re-expand and re-validate it more than once no matter how many times
# callers ask for it. Takes the raw table explicitly (rather than reaching
# for the OPCODE_TABLE constant itself) so do_expand_and_validate stays
# testable against a hand-built table, the way validate_opcode_table! is.
@expanded_table = nil

def expand_opcode_table(table)
  @expanded_table = do_expand_and_validate(table) if @expanded_table.nil?
  @expanded_table
end

# The actual work behind expand_opcode_table: turn the raw table into its
# expanded form, then fail fast on it -- with every problem reported at
# once -- rather than letting a bad table quietly produce a broken
# assembler or a broken decoder that only shows up much later at
# simulation time.
def do_expand_and_validate(table)
  expanded = table.each_with_index.map { |row, i| expand_entry(row, i) }.freeze
  validate_opcode_table!(expanded)
  expanded
end

def validate_opcode_table!(table)
  errors = []

  table.group_by { |e| e[:name] }.each do |name, rows|
    errors << "duplicate instruction name #{name.inspect} (#{rows.size} occurrences)" if rows.size > 1
  end

  # Opcode collisions can't actually happen while opcode == array index,
  # but this stays cheap insurance against a future refactor that adds an
  # explicit opcode: override back in.
  table.group_by { |e| e[:opcode] }.each do |opcode, rows|
    next unless rows.size > 1

    errors << "opcode #{opcode} (0x#{opcode.to_s(16)}) used by multiple instructions: " \
               "#{rows.map { |r| r[:name] }.join(', ')}"
  end

  table.each do |e|
    e[:steps].each_key do |step|
      if step < 2
        errors << "#{e[:name]}: step #{step} is reserved for instruction fetch (steps 0-1) -- " \
                   'instructions must start at step 2'
      elsif step >= MAX_STEPS
        errors << "#{e[:name]}: step #{step} is >= MAX_STEPS (#{MAX_STEPS})"
      end
    end
  end

  # argument: is an independently hand-written fact on each template/row --
  # nothing about the shape of `steps:` forces it to agree with what the
  # microcode actually does, so a copy-paste error could silently produce
  # an instruction that reads one operand word but that the assembler
  # thinks takes none (or vice versa), corrupting every instruction after
  # it in the assembled program with no error anywhere.
  #
  # The one reliable structural signal for "this instruction consumes an
  # operand word" is a step that asserts MI, CO, and CE *together*: that's
  # specifically "latch PC into the memory address register, then advance
  # PC" -- i.e. fetch the next word and move past it. CE shows up alone in
  # a couple of places for unrelated reasons (POPPC uses two bare CE steps
  # to skip past the JMP that follows a PUSHPC, not to consume an operand
  # of its own), which is exactly why this checks for the MI+CO+CE triple
  # together rather than just "does CE appear anywhere".
  table.each do |e|
    fetches_operand = e[:steps].values.any? { |s| (%i[MI CO CE] - s[:ctrl]).empty? }
    if e[:argument] && !fetches_operand
      errors << "#{e[:name]}: argument: true, but no step fetches an operand word " \
                 '(no step asserts MI+CO+CE together) -- argument: should probably be false'
    elsif !e[:argument] && fetches_operand
      errors << "#{e[:name]}: argument: false, but a step fetches an operand word " \
                 '(some step asserts MI+CO+CE together) -- argument: should probably be true'
    end
  end

  # Stack.v's read path (see the module itself) is built on the assumption
  # that a push and a pop never happen on the same cycle -- it uses that to
  # pick, unambiguously, which of two candidate registers is fresh.
  # Nothing in the datapath enforces that by itself; it's an invariant the *set of
  # instructions* has to uphold. Enforcing it here means it's checked once,
  # for every instruction, forever, instead of being something a future
  # instruction author has to remember on their own.
  table.each do |e|
    e[:steps].each do |step, data|
      next unless data[:ctrl].include?(:SPU) && data[:ctrl].include?(:SPO)

      errors << "#{e[:name]} step #{step}: asserts both SPU (push) and SPO (pop) together -- " \
                 'Stack.v assumes these never coincide on the same cycle'
    end
  end

  # Ram.v's read and write paths share one physical address port (this is a
  # single-port RAM) -- RI (write) and RE (read-trigger) can never both be
  # asserted on the same cycle, for the same reason SPU/SPO can't: there's
  # only one address the RAM can be looking at in a given cycle, and RI
  # needs it to mean "the held MAR address" while RE needs it to mean "the
  # live bus value" at the exact same moment.
  table.each do |e|
    e[:steps].each do |step, data|
      next unless data[:ctrl].include?(:RI) && data[:ctrl].include?(:RE)

      errors << "#{e[:name]} step #{step}: asserts both RI (write) and RE (read-trigger) together -- " \
                 'Ram.v assumes these never coincide on the same cycle'
    end
  end

  # RE is what actually tells Ram.v to sample an address and start a read;
  # RO just shows whatever the RAM's output register is currently holding,
  # completely decoupled from addressing. That means RO is only meaningful
  # exactly one step after the RE that primed it -- an RO with no RE on the
  # immediately preceding step reads garbage (whatever the output register
  # was last set to by some earlier, unrelated read), not the value the
  # instruction actually wants.
  table.each do |e|
    e[:steps].each do |step, data|
      next unless data[:ctrl].include?(:RO)

      prev = e[:steps][step - 1]
      next if prev && prev[:ctrl].include?(:RE)

      errors << "#{e[:name]} step #{step}: asserts RO, but step #{step - 1} does not assert RE -- " \
                 'RO only returns valid data exactly one step after RE triggers the read'
    end
  end

  return if errors.empty?

  raise "opcodes.rb: invalid OPCODE_TABLE:\n  - #{errors.join("\n  - ")}"
end
