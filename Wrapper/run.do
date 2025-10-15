vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.SPI_Wrapper_top -classdebug -uvmcontrol=all -cover
add wave /SPI_Wrapper_top/SPI_Wrapperif/*
add wave -position insertpoint sim:/SPI_Wrapper_top/RAMif/*
add wave -position insertpoint  \
sim:/SPI_Wrapper_top/GM/tx_data \
sim:/SPI_Wrapper_top/GM/rx_data \
sim:/SPI_Wrapper_top/GM/MISO
coverage save SPI_Wrapper_test.ucdb -onexit
run -all