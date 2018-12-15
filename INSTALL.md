# Running the console

## Preparation

First, install the Git submodule where I'm keeping my libraries:

    git submodule update --init

I'm using the following software:

* Icarus Verilog
* [IceStorm toolchain](http://www.clifford.at/icestorm/)
* TinyFPGA BX software (`pip install --user tinyprog`)
* GTKWave (for `make sim` target)
* [tortilla8](https://github.com/aanunez/tortilla8/tree/master/tortilla8) (for
  compiling CHIP-8 ROMs from assembly language):

        pip3 install --user 'git+https://github.com/aanunez/tortilla8.git'
        sudo apt install python3-tk

See also [setup instructions for my FPGA tutorial](https://pwmarcz.github.io/fpga-tutorial/fpga.html).

## Uploading project to board

To flash the project, connect the board and run:

    make flash-chip8

This will also compile and run the default "game", which is `counter`
(`asm/counter.c8asm`). To use a different one (e.g. `tetris`), run:

    make flash-chip8 GAME=tetris

The Makefile searches for games in the `games` directory.

## Running tests

To run a single test-bench:

    make run V=cpu_tb.v

To run all tests:

    make test
