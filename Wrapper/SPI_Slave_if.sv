interface SPI_Slave_if (clk);
  input bit clk;
logic            MOSI, rst_n, SS_n, tx_valid;
logic      [7:0] tx_data;
logic [9:0] rx_data;
logic rx_valid, MISO;
logic [2:0] cs_sva;
endinterface : SPI_Slave_if