onerror {exit -code 1}
vlib work
vlog -work work Lab.vo
vlog -work work mips_processor.vwf.vt
vsim -novopt -c -t 1ps -L cyclonev_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate_ver -L altera_lnsim_ver work.mips_processor_vlg_vec_tst -voptargs="+acc"
vcd file -direction Lab.msim.vcd
vcd add -internal mips_processor_vlg_vec_tst/*
vcd add -internal mips_processor_vlg_vec_tst/i1/*
run -all
quit -f
