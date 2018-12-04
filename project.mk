
# pip3 install --user 'git+https://github.com/aanunez/tortilla8.git
# sudo apt install python3-tk

TESTS = $(patsubst %.c8asm,build/%.hex,$(wildcard *.c8asm))

build/cpu_tb.out: $(TESTS)

build/%.ch8: %.c8asm
	tortilla8 assemble $< -o $(@:.ch8=)

build/%.hex: build/%.ch8
	hexdump -v -e '/1 "%02X "' $< > $@
