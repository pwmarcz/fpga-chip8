# CHIP-8 on FPGA

This a [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) emulator working on an
FPGA chip (TinyFPGA BX board with iCE40-LP8K chip).

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

## Running tests

To run a single test-bench:

    make run V=cpu_tb.v

To run all tests:

    make test

## Flashing

To flash the project, connect the board and run:

    make flash V=chip.v RAM_FILE=build/default.hex BOARD=bx

TODO different games

## Connecting the peripherals

I'm using the following:

* [SparkFun 16-button keyboard](https://www.sparkfun.com/products/14881)
* [WaveShare 128x64px monochrome OLED screen](https://www.waveshare.com/0.96inch-oled-b.htm)

(TODO how to connect on a breadboard)

## Flashing other games

(TODO)

## Implementation notes

(TODO)

## License

By Paweł Marczewski <pwmarcz@gmail.com>.

Licensed under MIT (see [`LICENSE`](LICENSE)), unless otherwise specified.

## See also

* [fpga-tutorial](https://github.com/pwmarcz/fpga-tutorial) - my FPGA workshop
* [fpga-experiments](https://github.com/pwmarcz/fpga-experiments) - a repo where I prototyped some of these things
* [CHIP-8 technical specification](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
