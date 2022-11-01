#!/usr/bin/env ruby
# Assembles machine code for the SAP2
# Currently the OPCODE table here, unfortunately, can get out of sync with Instruction_Decoder.v
# as there is no automated mechanism right now to generate one from the other
# SYNTAX
#   For comments use ; ie
#     ; Multiplication subrouting
#   For CONSTANTS use CONSTANT <NAME> <VALUE> ie
#     CONSTANT FOO 3
#     constants can be used as array indicies, array lengths, or in other general commands
#     constants cannot start with digits
#     right now all consatnts must have numbers on the other side, they cannot be composed
#   For LABELS use <LABEL>:, ie
#     START:
#     Labels will be evaluated to a hardcoded address so then a command like JMP START will have START substituded back in
#     Labels cannot start with digits
#   Variables must be reserved in the top of the file, and are always initialized to all zeros. C-like array indexing is allowed. Multiple variables can be reserved on one line
#     RESERVE x[2] y z[3]
#     Reserves x of length 2 words, y of length 1 word, z of length 3 words
#     Variables will be evaluated to hardcoded address so then a command like STA x[0] will store A in x[0].
#     LDIA x will store the address of x into A which could be useful for some of the more complex addressing modes
#     x is equivalent to x[0]. Out of bound indexing is enforced and disallowed at compile time
#     Variables cannot start with digits
#     There is no guarentee in the ordering or position of the variables, other than that they will be after all user provided instructions and will
#     be non overlapping with one another
#   Generating programs that are longer than the bounds of RAM are disallowed at compile time

require 'optparse'
require 'set'

def s_to_i_find_base(s, allow_zero: true, msg: '')
  r = if h = s.match?(/^0?x(\h+)$/)
        s.to_i(16)
      elsif h = s.match?(/^0?b([01]+)$/)
        s.to_i(2)
      elsif h = s.match?(/^(\d+)$/)
        s.to_i(10)
      else
        raise "Unknown base for apparent integer #{s}, use 0x for hex and 0b for binary, otherwise assume dec#{msg}"
      end
  if r == 0 && !allow_zero
    raise "Integer #{s} (#{r}) cannot be zero#{msg}"
  end
  r
end

RAM_WIDTH          = 16
RAM_WIDTH_HEX_CHAR = Rational(RAM_WIDTH, 4).ceil
RAM_DEPTH          = 2**16
COMMENT_DELIMITER  = ';'
ARG_BITS           = 16 # note arguments on on the next word

OPS = {
  NOP:    { opcode: 0x0000, argument: false },
  LDA:    { opcode: 0x0001, argument: true },
  LDB:    { opcode: 0x0002, argument: true },
  LDC:    { opcode: 0x0003, argument: true },
  STA:    { opcode: 0x0004, argument: true },
  STT:    { opcode: 0x0005, argument: true },
  STB:    { opcode: 0x0006, argument: true },
  STC:    { opcode: 0x0007, argument: true },
  LDTA:   { opcode: 0x0008, argument: false },
  LDTB:   { opcode: 0x0009, argument: false },
  LDTC:   { opcode: 0x000a, argument: false },
  STTA:   { opcode: 0x000b, argument: false },
  STTB:   { opcode: 0x000c, argument: false },
  STTC:   { opcode: 0x000d, argument: false },
  MOVAT:  { opcode: 0x000e, argument: false },
  MOVAB:  { opcode: 0x000f, argument: false },
  MOVAC:  { opcode: 0x0010, argument: false },
  MOVTA:  { opcode: 0x0011, argument: false },
  MOVTB:  { opcode: 0x0012, argument: false },
  MOVTC:  { opcode: 0x0013, argument: false },
  MOVBA:  { opcode: 0x0014, argument: false },
  MOVBT:  { opcode: 0x0015, argument: false },
  MOVBC:  { opcode: 0x0016, argument: false },
  MOVCA:  { opcode: 0x0017, argument: false },
  MOVCT:  { opcode: 0x0018, argument: false },
  MOVCB:  { opcode: 0x0019, argument: false },
  PUSHA:  { opcode: 0x001a, argument: false },
  POPA:   { opcode: 0x001b, argument: false },
  PUSHT:  { opcode: 0x001c, argument: false },
  POPT:   { opcode: 0x001d, argument: false },
  PUSHB:  { opcode: 0x001e, argument: false },
  POPB:   { opcode: 0x001f, argument: false },
  PUSHC:  { opcode: 0x0020, argument: false },
  POPC:   { opcode: 0x0021, argument: false },
  PUSHPC: { opcode: 0x0022, argument: false },
  POPPC:  { opcode: 0x0023, argument: false },
  PUSHMA: { opcode: 0x0024, argument: false },
  POPMA:  { opcode: 0x0025, argument: false },
  OUTA:   { opcode: 0x0026, argument: false },
  OUTT:   { opcode: 0x0027, argument: false },
  OUTB:   { opcode: 0x0028, argument: false },
  OUTC:   { opcode: 0x0029, argument: false },
  LDIA:   { opcode: 0x002a, argument: true },
  LDIB:   { opcode: 0x002b, argument: true },
  LDIC:   { opcode: 0x002c, argument: true },
  JMP:    { opcode: 0x002d, argument: true },
  JIZ:    { opcode: 0x002e, argument: true },
  JIC:    { opcode: 0x002f, argument: true },
  JIO:    { opcode: 0x0030, argument: true },
  ADDI:   { opcode: 0x0031, argument: true },
  SUBI:   { opcode: 0x0032, argument: true },
  ANDI:   { opcode: 0x0033, argument: true },
  ORI:    { opcode: 0x0034, argument: true },
  XORI:   { opcode: 0x0035, argument: true },
  ADDB:   { opcode: 0x0036, argument: false },
  SUBB:   { opcode: 0x0037, argument: false },
  ANDB:   { opcode: 0x0038, argument: false },
  ORB:    { opcode: 0x0039, argument: false },
  XORB:   { opcode: 0x003a, argument: false },
  ADDC:   { opcode: 0x003b, argument: false },
  SUBC:   { opcode: 0x003c, argument: false },
  ANDC:   { opcode: 0x003d, argument: false },
  ORC:    { opcode: 0x003e, argument: false },
  XORC:   { opcode: 0x003f, argument: false },
  SL:     { opcode: 0x0040, argument: false },
  SR:     { opcode: 0x0041, argument: false },
  ASR:    { opcode: 0x0042, argument: false },
  ROL:    { opcode: 0x0043, argument: false },
  ROR:    { opcode: 0x0044, argument: false },
  ROLC:   { opcode: 0x0045, argument: false },
  RORC:   { opcode: 0x0046, argument: false },
  INV:    { opcode: 0x0047, argument: false },
  NEG:    { opcode: 0x0048, argument: false },
  ABS:    { opcode: 0x0049, argument: false },
  CHK:    { opcode: 0x004a, argument: false },
  HALT:   { opcode: 0xffff, argument: false }
}

options = {
  verbose:  false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: assembler.rb -i INPUT_FILE -o OUTPUT_FILE'
  opts.on('-i', '--input-file IN_FILE', 'File to parse assembly from. Required') do |i|
    options[:input_file] = i
  end
  opts.on('-o', '--output-file OUT_FILE', 'File to write machine code to. Required') do |o|
    options[:output_file] = o
  end
  opts.on('-v', '--[no-]verbose', "Print verbose messages as we parse the file. Defaults to #{options[:verbose]}") do |v|
    options[:verbose] = v
  end
  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

labels_table         = {}
constants_table      = {}
variables_table      = {}
instructions         = []
current_addr         = 0

known_symbols = Set.new(OPS.keys + %i[RESERVE CONSTANT])

File.readlines(options.fetch(:input_file)).each_with_index do |l, i|
  l.strip!
  l.slice!(0..l.index(COMMENT_DELIMITER)-1) if l.match?(COMMENT_DELIMITER)
  next if l.empty?
  l = l.split
  # we have a variable declaration
  if l[0] == 'RESERVE'
    if l.size == 1
      puts "RESERVE on line #{i} must have following arguments"
    end
    l.slice(1, l.size).each do |v|
      if v.start_with?(/\d/)
        puts "Apparent variable #{v} on line #{i} cannot start with a digit"
        exit 1
      end
      if m = v.match(/(..*)\[(..*)\]/)
        n   = m[1].to_sym
        if known_symbols.include?(n)
          puts "Apparent variable #{n} on line #{i} cannot exist because it conflicts with known symbols"
          exit 1
        end
        known_symbols << n
        # Check if its a known constant
        if (len = constants_table[m[2].to_sym])
          nil
        else
          len = s_to_i_find_base(m[2], allow_zero: false, msg: " Variable #{v} on line #{i}")
        end
        variables_table.merge!({ n =>  { length: len, addr: nil } })
      else
        n   = v.to_sym
        if known_symbols.include?(n)
          puts "Apparent variable #{n} on line #{i} cannot exist because it conflicts with known symbols"
          exit 1
        end
        known_symbols << n
        len = 1
        variables_table.merge!({ n =>  { length: len, addr: nil } })
      end
    end
    next
  end
  # We have a constant declaration
  if l[0] == 'CONSTANT'
    if l.size != 3
      puts "CONSTANT on line #{i} must have two arguments"
      exit 1
    end
    c = l[1]
    if c.start_with?(/\d/)
      puts "Apparent constant #{c} on line #{i} cannot start with a digit"
      exit 1
    end
    c = c.to_sym
    if known_symbols.include?(c)
      puts "Apparent constant #{c} on line #{i} cannot exist because it conflicts with known symbols"
      exit 1
    end
    known_symbols << c
    v = s_to_i_find_base(l[2], msg: " Constant #{c} on line #{i}")
    constants_table.merge!({ c => v })
    next
  end
  # we have a label, add to label table
  if l.size == 1 && l[0].end_with?(':')
    if l[0].start_with?(/\d/)
      puts "Apparent label #{l[0]} on line #{i} cannot start with a digit"
      exit 1
    end
    label = l[0].slice(0...l[0].size-1).to_sym
    if known_symbols.include?(label)
      puts "Apparent label #{label} on line #{i} cannot exist because it conflicts with known symbols"
      exit 1
    end
    known_symbols << label
    labels_table.merge!({ label => current_addr })
    next
  end
  op = l[0].to_sym
  # we have an opcode
  if (o = OPS[op])
    if o.fetch(:argument)
      if l.size == 2
        instructions << [op, l[1]]
        current_addr += 2
        next
      else
        puts "For opcode #{l[0]} on line #{i}, should have one argument, not #{l.size - 1} arguments"
        exit 1
      end
    else
      if l.size == 1
        instructions << [op]
        current_addr += 1
        next
      else
        puts "For opcode #{l[0]} on line #{i}, should have zero arguments, not #{l.size - 1} arguments"
        exit 1
      end
    end
  else
    puts "Unknown op #{l[0]} on line #{i}"
    exit 1
  end
end

end_of_instructions_addr = current_addr

# tack on variables to the end of memory
variables_table.each do |v, info|
  info[:addr] = current_addr
  current_addr += info.fetch(:length)
end

if current_addr > RAM_DEPTH
  puts "Program takes up #{current_addr} words, which is too long for a #{RAM_DEPTH} sized ram"
  exit 1
end

if options.fetch(:verbose)
  puts "labels table:"
  labels_table.each { |l, v| puts "#{l.to_s.rjust(10)}: #{v}" }

  puts "constants table:"
  constants_table.each { |l, v| puts "#{l.to_s.rjust(10)}: #{v}" }

  puts "variables table:"
  variables_table.each { |l, v| puts "#{l.to_s.rjust(10)}: #{v}" }

  puts "pre processed instructions:"
  instructions.each.with_index { |l, i| puts "#{i.to_s.rjust(3)}: #{l}" }
end

instructions.each.with_index do |instr, i|
  if instr.size == 2
    # Substitute labels
    if (l = labels_table[instr[1].to_sym])
      instr[1] = l
    # Substitude variable addresses
    elsif (v = variables_table[instr[1].split('[').first.to_sym])
      a   = v.fetch(:addr)
      len = v.fetch(:length)
      if m = instr[1].match(/\[(..*)\]/)
        if (ix = constants_table[m[1].to_sym])
          nil
        else
          ix = s_to_i_find_base(m[1], allow_zero: true, msg: " Variable #{m} substitution on instruction #{instr}")
        end
        if ix >= len
          puts "cannot index variable #{instr[1]} with length longer than its length of #{len} on instruction #{instr}"
          exit 1
        end
        a += ix
      end
      instr[1] = a
    # substitute constants
    elsif (c = constants_table[instr[1].to_sym])
      instr[1] = c
    # update numbers
    else
      instr[1] = s_to_i_find_base(instr[1], msg: "Updating number in instruction #{instr}")
    end
    if instr[1] >= 2**ARG_BITS
      puts "Argument for #{instr} cannot fit in #{ARG_BITS}"
      exit 1
    end
  end
end

if options.fetch(:verbose)
  puts "post processed instructions:"
  instructions.each.with_index { |l, i| puts "#{i.to_s.rjust(3)}: #{l}" }
end

File.open(options.fetch(:output_file), 'w') do |f|
  instructions.each do |instr|
    op = OPS.fetch(instr[0]).fetch(:opcode)
    f.puts op.to_s(16).rjust(RAM_WIDTH_HEX_CHAR, '0')
    f.puts instr[1].to_s(16).rjust(RAM_WIDTH_HEX_CHAR, '0') if instr[1]
  end
  (RAM_DEPTH - end_of_instructions_addr).times do
    f.puts ''.rjust(RAM_WIDTH_HEX_CHAR, '0')
  end
end
