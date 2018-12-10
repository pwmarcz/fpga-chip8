# CHIP-8 on FPGA

This a [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) emulator working on an
FPGA chip (TinyFPGA BX board with iCE40-LP8K chip).

## Running tests

You'll need Icarus Verilog. To run a single test-bench:

    make run V=cpu_tb.v

To run all tests:

    make test

## Flashing

You will need the [IceStorm toolchain](http://www.clifford.at/icestorm/) and
TinyFPGA BX board. To flash the project, connect the board and run (TODO):

    make flash V=chip.v RAM_FILE=build/default.hex BOARD=bx

See also [setup instructions for my FPGA tutorial](https://pwmarcz.github.io/fpga-tutorial/fpga.html).

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
