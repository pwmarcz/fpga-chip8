
# Don't run anything by default
.PHONY: all
all:

# Custom project configuration
-include ./project.mk

# Don't delete these
.PRECIOUS: build/%.d build/%.blif build/%.bin build/%.asc

# Top module
TOP ?= top

# Tool paths

# Use apio toolchain
TOOLCHAIN = $(HOME)/.apio/packages/toolchain-icestorm/bin
export PATH := $(TOOLCHAIN):$(PATH)

YOSYS ?= yosys
PNR ?= arachne-pnr
ICEPACK ?= icepack
ICEPROG ?= iceprog
TINYPROG ?= tinyprog
ICETIME ?= icetime
IVERILOG ?= iverilog
GTKWAVE ?= gtkwave

SHARE_ICEBOX = $$(dirname $$(which $(ICETIME)))/../share/icebox

ifeq ($(USE_SUDO),1)
ICEPROG := sudo $$(which $(ICEPROG))
TINYPROG := sudo $$(which $(TINYPROG))
endif

MAKEDEPS = ./make-deps

# Board-specific configuration

BOARD ?= icestick

YOSYS_OPTS =

ifeq ($(BOARD),icestick)
PNR_OPTS = -d 1k -P tq144
DEVICE = hx1k
CHIPDB = 1k
PROG = $(ICEPROG)
endif

ifeq ($(BOARD),bx)
PNR_OPTS = -d 8k -P cm81
DEVICE = lp8k
CHIPDB = 8k
PROG = $(TINYPROG) -p
endif

ifndef VERBOSE
PNR_OPTS := -q $(PNR_OPTS)
YOSYS_OPTS := -q $(YOSYS_OPTS)
endif

# Dependencies

build/%.d: %.v $(MAKEDEPS)
	@mkdir -p $(dir $@)
	@$(MAKEDEPS) $(@:.d=.bx.blif) $< > $@
	@$(MAKEDEPS) $(@:.d=.icestick.blif) $< >> $@
	@$(MAKEDEPS) $(@:.d=.out) $< >> $@

# Synthesis

build/%.$(BOARD).blif: %.v build/%.d
	$(YOSYS) $(YOSYS_OPTS) \
		-p "verilog_defines -DBOARD_$(BOARD) -DBOARD=$(BOARD)" \
		-p "read_verilog -noautowire $<" \
		-p "synth_ice40 -top $(TOP) -blif $@"

build/%.$(BOARD).asc: build/%.$(BOARD).blif pcf/$(BOARD).pcf
	$(PNR) -p pcf/$(BOARD).pcf $(PNR_OPTS) $< -o $@

build/%.bin: build/%.asc
	$(ICEPACK) $< $@

# Simulation

build/%.out: %.v build/%.d
	$(IVERILOG) -DVCD_FILE=\"build/$(<:.v=.vcd)\" -o $@ $<

# Top-level goals (flash, sim, run, time)

flash sim run time::
ifeq ($(V),)
	$(error Define target name first, e.g.: make run V=myfile.v)
endif

.PHONY: flash
flash:: build/$(V:.v=.$(BOARD).bin)
	$(PROG) $<

.PHONY: sim
sim:: run
	$(GTKWAVE) build/$(V:.v=.vcd)

.PHONY: run
run:: build/$(V:.v=.out)
	./$<

.PHONY: time
time:: build/$(V:.v=.$(BOARD).asc)
	$(ICETIME) -d $(DEVICE) -C $(SHARE_ICEBOX)/chipdb-$(CHIPDB).txt $<

# Cleanup

.PHONY: clean
clean:
	rm -f build/*

include $(wildcard build/*.d)
