include fpga-tools/fpga.mk

HEX = $(patsubst asm/%.c8asm,build/%.hex,$(wildcard asm/*.c8asm))

build/cpu_tb.out: $(HEX)

build/%.ch8: asm/%.c8asm
	tortilla8 assemble $< -o $(@:.ch8=)

build/%.hex: build/%.ch8
	hexdump -v -e '/1 "%02X "' $< > $@
