MODULE_NAME    := Top

VERILATED_NAME := V${MODULE_NAME}

RAMFILE        := ram.hex

ASSEMBLER      := assembler.rb
OPCODES        := opcodes.rb

GEN_DECODER    := gen_decoder.rb
DECODER        := Instruction_Decoder.v
DECODER_ERB    := Instruction_Decoder.v.erb

OBJ_DIR        := obj_dir

LD_FLAGS       := -flto

CFLAGS         := --std=c++17 -O3 -flto

V_FLAGS        := -Wall -O3 --trace --Mdir ${OBJ_DIR} --prefix ${VERILATED_NAME}

.PHONY: run all clean

run: all
	${OBJ_DIR}/./${VERILATED_NAME}

all: ${OBJ_DIR}/${VERILATED_NAME} ${RAMFILE}

${RAMFILE} : example.asm ${ASSEMBLER} ${OPCODES}
	if [ ! -f $@ ]; then ./${ASSEMBLER} -i $< -o $@ ; else touch $@; fi

# Instruction_Decoder.v is generated from the same opcode table the
# assembler uses -- it isn't checked in (see .gitignore), so regenerate
# it whenever the template or the microcode table changes.
${DECODER} : ${DECODER_ERB} ${OPCODES} ${GEN_DECODER}
	./${GEN_DECODER} $@

${OBJ_DIR}/${VERILATED_NAME} : % : %.mk ${MODULE_NAME}.cpp
	cd ${OBJ_DIR}; make -f $(patsubst ${OBJ_DIR}/%,%,$<)

# ${DECODER} is listed explicitly (not just picked up by the *.v glob)
# so that a clean checkout -- where Instruction_Decoder.v doesn't exist
# yet at Make's parse time -- still generates it before verilating.
${OBJ_DIR}/${VERILATED_NAME}.mk : ${MODULE_NAME}.v ${DECODER} $(filter-out ${MODULE_NAME}, *.v) *.vi
	verilator ${V_FLAGS} -cc $< --exe $(patsubst %.v,%.cpp,$<) -LDFLAGS "${LD_FLAGS}" -CFLAGS "${CFLAGS}"

clean:
	rm -rf ${OBJ_DIR} *.vcd ${DECODER}
