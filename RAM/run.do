vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.top -classdebug -uvmcontrol=all -cover
add wave /top/RAM_if/*
coverage save RAM_test.ucdb -onexit
run -all

