import uvm_pkg::*;
`include "uvm_macros.svh"
import RAM_test_pkg::*; 
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
  RAM_if RAM_if (clk);
  RAM DUT (
    RAM_if.din,clk,RAM_if.rst_n,RAM_if.rx_valid,RAM_if.dout,RAM_if.tx_valid
    
  );

  bind RAM RAM_SVA SVA (    
    RAM_if.din,clk,RAM_if.rst_n,RAM_if.rx_valid,RAM_if.dout,RAM_if.tx_valid
    );

    
  // run test using run_test task
  initial begin
  uvm_config_db#(virtual RAM_if)::set(null , "uvm_test_top" , "RAM_IF" , RAM_if);
  run_test("RAM_test");
  end

endmodule