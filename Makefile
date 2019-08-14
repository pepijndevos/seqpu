SOURCES=alu.vhd inc.vhd cpu.vhd

ifdef SYMBIOTIC_LICENSE
		YOSYSARGS=-p "verific -vhdl ${SOURCES}; verific -import $*"
else
		YOSYSARGS=-m ghdl -p "ghdl --std=08 ${SOURCES} -e $*"
endif

%_rtl.il: %.vhd ${SOURCES}
	yosys -q ${YOSYSARGS} -p "script ../synth_74.ys; dump -o $@"

%.il: %.vhd ${SOURCES}
	yosys -q ${YOSYSARGS} -p "dump -o $@"

%.stat: %.il
	yosys -q -p "tee -o $@ stat" $<

%.v: %.il
	yosys -q -p "write_verilog $@" $<

%.v: ../%.lib
	yosys -q -p "read_liberty $<" -p "write_verilog $@"

%.vvp: %.v %_tb.v 74series.v ../74_models.v
	iverilog -o $@ $^

%.vcd: %.vvp
	vvp $<

