SOURCES=alu.vhd inc.vhd cpu.vhd display.vhd vga_controller.vhd ice40_top.vhd
VSOURCES=bram.v bram10.v tilerom.v icepll.v

ifdef SYMBIOTIC_LICENSE
		YOSYSARGS=-p "verific -vhdl ${SOURCES}; verific -import $*"
else
		YOSYSARGS=-m ghdl -p "ghdl --std=08 ${SOURCES} -e $*"
endif

%.mem: %.asm
	python asm/asm.py $< > $@
	cat presentation.mem >> $@

%_rtl.il: %.vhd ${SOURCES}
	yosys -q ${YOSYSARGS} -p "script ../synth_74.ys; dump -o $@"

%.il: %.vhd ${SOURCES}
	yosys -q ${YOSYSARGS} -p "dump -o $@"

%.stat: %.il
	yosys -q -p "tee -o $@ stat" $<

%.v: %.il
	yosys -q -p "proc; write_verilog $@" $<

%.v: ../%.lib
	yosys -q -p "read_liberty $<" -p "write_verilog $@"

bram.v: rom.mem

# simulation

%.vvp: %.v %_tb.v bram.v tilerom.v 74ac.v ../74_models.v
	iverilog -o $@ $^

%.vcd: %.vvp
	vvp $<

# ice40

%.json: %.il ${VSOURCES}
	yosys -q -p 'synth_ice40 -top $* -json $@' $^

%.asc: %.json icebreaker.pcf
	nextpnr-ice40 --up5k --package sg48 --json $< --pcf icebreaker.pcf --asc $@

%.bin: %.asc
	icepack $< $@

prog: ice40_top.bin
	sudo iceprog $<

