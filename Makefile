ifdef SYMBIOTIC_LICENSE
		YOSYSARGS=-p "verific -vhdl $<; verific -import $*"
else
		YOSYSARGS=-m ghdl -p "ghdl $*"
endif

%.il: %.vhd ../74series.lib ../74_models.v ../74_adder.v ../74_cmp.v ../74_eq.v ../74_dffe.v ../74_mux.v ../synth_74.ys
	ghdl -a $<
	yosys -q ${YOSYSARGS} -p "script ../synth_74.ys; dump -o $@"

%.stat: %.il
	yosys -q -p "tee -o $@ stat" $<

%.v: %.il
	yosys -q -p "write_verilog $@" $<
