# SAP2

## Purpose:

This collection of RTL is meant to model an 8-bit SAP2 computer as explained by Albert Paul Malvino,
for an interproduction to the concepts, see my [SAP1](https://github.com/jshaker000/SAP1)

This project was part of my own learning experience of Computer Architecture and Verilog,
and I hope that this finds someone else who finds it useful as an introduction to either topic.

The bench is written in C++ and is compiled using [Verilator](https://www.veripool.org/wiki/verilator).

## Theory of Operation
This computer is generally based on the SAP1 archetecture, but has these enhancements:

    1. Extended RAM to wordize of 16 bits, depth of 64k
    2. Extended all registers, including Program Counter, Memory Address Register, Bus to 16 bits to facilitate
    3. Added stack functionality
    4. Added additional registers: Temp, B, C and added move instructions for each of them
    5. Added ability to address into memory using registers, essentially allowing for array access

An example program is attached in `example.asm`, and is automatically assembled by running `make` via `assembler.rb` to generate `ram.hex` unless that file already exists.
Running make runs the program in `ram.hex` so you can write and assemble your own code there if desired. Note that the assembler currently does not automatically stay in sync
with the `Instruction_Decoder.v` and will likely need edits if you need to update that file. These two files `assembler.rb` and `Instruction_Decoder.v` kind of show the brains of the
computer, how it does it and what it does.

There is an additional example program in `fib.asm`.

The assembler file has a lot of comments explaining the valid syntax for it.

The control words are defined in `control_words.vi` to be shared between other files as needed.

## Installation and Usage
This is tested to work on major Linux distros. You will need to install Verilator, gcc, and
ncurses (some distros will seperate into devel and non devel, you need the devel version).

You will also need `ruby` installed to run the assembler, though I suppose it isnt technically needed if you dont
mind hand writing machine code.

From there, simply running *make* should be enough to verilate, build, and run your bench.
You should place your RAM file in "ram.hex". I've left an example in the repo.

The main bench is in *Top.cpp*. You have the option to dump the outputs to a trace file. This will create a \*.vcd which you can open with GTKWAVE.
This will show you all waveforms. You can combine these options using enviornment variables.
Setting a variable to "1" will set it. Setting it to anything else, or leaving unset will keep it disabled.

The bench tries to prevent infinite loops by killing the simulation is more than `MAX_STEPS` clock cycles have passed.
You can freely set this to any integer you like.

IE

    DUMP_TRACES=1 MAX_STEPS=100000 make

You can set the DUMP_F variable to name the vcd file (otherwise there is a default name).

You also could make some C model of what you expect the Computer to do and then just use if statements to compare.
Then, if your program doesn't exit out, you will know that it succeeded - and viewing the waveform would be unnecessary.
You can make more benches and update the makefile appropriately if you like.

## Further Work

### Compiler
I'd love to make some scripts that take plain text and can compile to both Instruction\_Decoder.v and also use that file
to convert instructions into the ram file. Especially with a stack, being able to maintain labels and automate function calling would be great.

### FPGA Implementation
#### Output Module
You could implement a pipelined Double-Dabble Module and tie that output then the 7seg decoder. Many FPGAs then will have a scheme
that you enable only one Seven Seg Digit at a time, so you'll need a fast clock to shift through each BCD digit and drive it quick enough that it looks
like they are all being held at once.

I didnt want to go through the trouble of making a binary to bcd converter then bd to 7seg.
Also, each FPGA will have a different port config to drive the 7segs (shift registers, active high, active low).
So that is an open excercise.
Currently, I am able to synthesize this design on Vivado when I map out\_data to a handful of LEDs. (The whole design will be optimized out if there is no
output port)

#### Reset Line
Some ability to reset everyhting -> perhaps also have  "backup ram (functionally rom)" and some bootstrapping module to copy the backup ram
back into the main ram to easily restart

#### UART RAM Programming
Some way to reprogram the RAM from a computer / live so that we dont have to reelaborate and synthesisize and all each time would be nice.
Perhaps having a UART controller listen to a control word that turns the computer into RESET mode, allows you to program the RAM, and then lifts reset mode.
I don't think this would be too hard, honestly. This could be a plausible alternative to a reset line and having a backup Ram.
