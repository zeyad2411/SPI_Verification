vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.top -classdebug -uvmcontrol=all -cover
add wave /top/SPI_Slave_if/*
coverage save SPI_Slave_test.ucdb -onexit
run -all

