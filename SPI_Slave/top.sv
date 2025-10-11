import uvm_pkg::*;
`include "uvm_macros.svh"
import SPI_Slave_test_pkg::*; // bn7ot el test gwa el top
import shared_pkg::*;
module top();
 bit clk;
  // Clock generation
  initial begin
  clk=0;
  forever 
  #5 clk = ~clk;
end
  // Instantiate the interface and DUT
  SPI_Slave_if SPI_Slave_if (clk);
  SLAVE DUT (
    .clk(SPI_Slave_if.clk),
    .rst_n(SPI_Slave_if.rst_n),
    .MOSI(SPI_Slave_if.MOSI),
    .SS_n(SPI_Slave_if.SS_n),
    .tx_valid(SPI_Slave_if.tx_valid),
    .tx_data(SPI_Slave_if.tx_data),
    .rx_data(SPI_Slave_if.rx_data),
    .rx_valid(SPI_Slave_if.rx_valid),
    .MISO(SPI_Slave_if.MISO)
  );


  bind SLAVE SPI_Slave_SVA SVA (    
    .clk(SPI_Slave_if.clk),
    .rst_n(SPI_Slave_if.rst_n),
    .MOSI(SPI_Slave_if.MOSI),
    .SS_n(SPI_Slave_if.SS_n),
    .tx_valid(SPI_Slave_if.tx_valid),
    .tx_data(SPI_Slave_if.tx_data),
    .rx_data(SPI_Slave_if.rx_data),
    .rx_valid(SPI_Slave_if.rx_valid),
    .MISO(SPI_Slave_if.MISO)
    );
  // run test using run_test task
  initial begin
  uvm_config_db#(virtual SPI_Slave_if)::set(null , "uvm_test_top" , "SPI_Slave_IF" , SPI_Slave_if);
  run_test("SPI_Slave_test");
  end

endmodule