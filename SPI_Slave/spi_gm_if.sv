interface SPI_gm_if (clk);
  input bit clk;

logic [9:0] rx_data_gm;
logic rx_valid_gm, MISO_gm;
logic [2:0] cs_sva_gm;
endinterface 