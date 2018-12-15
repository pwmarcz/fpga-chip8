
BOARD = bx

include fpga-tools/fpga.mk

HEX = $(patsubst asm/%.c8asm,build/%.hex,$(wildcard asm/*.c8asm))

build/cpu_tb.out: $(HEX)

build/%.ch8: asm/%.c8asm
	tortilla8 assemble $< -o $(@:.ch8=)

build/%.hex: build/%.ch8
	hexdump -v -e '/1 "%02X "' $< > $@

build/%.hex: games/%.ch8
	hexdump -v -e '/1 "%02X "' $< > $@

GAME ?= counter

.PHONY: flash-chip8
flash-chip8: build/chip8.$(BOARD).$(GAME).bin
	$(PROG) $<

.PHONY: bin-chip8
bin-chip8: build/chip8.$(BOARD).$(GAME).bin

build/chip8.$(BOARD).$(GAME).asc: build/chip8.$(BOARD).asc build/$(GAME).hex
	icebram random.hex build/$(GAME).hex <$< >$@
