import shared_pkg::*;

module RAM_SVA (
    din,clk,rst_n,rx_valid,dout,tx_valid
);

input      [9:0] din;
input            clk, rst_n, rx_valid;

input  [7:0] dout;
input       tx_valid;




// SVA properties

// Reset sequence
property p_reset_low;
  @(posedge clk) (~rst_n) |=> (tx_valid == 0 && dout == 0);
endproperty

a_reset_low: assert property(p_reset_low); 


property p_txvalid_low_in_input_phase;
  @(posedge clk) disable iff (!rst_n)
    (rx_valid && (din[9:8]  != 2'b11)) |=> (tx_valid == 0);
endproperty

a_txvalid_low_in_input_phase: assert property(p_txvalid_low_in_input_phase) ;


property p_txvalid_pulse_when_read;
  @(posedge clk) disable iff (!rst_n)
    (rx_valid && (din[9:8] == 2'b11 )) |=> (tx_valid);
endproperty

a_txvalid_pulse_when_read: assert property(p_txvalid_pulse_when_read) ;

property p_txvalid_pulse_after_read;
  @(posedge clk) disable iff (!rst_n)
    (tx_valid && $past(din[9:8]) == 2'b11) |=> ( !tx_valid);
endproperty

a_txvalid_pulse_after_read: assert property(p_txvalid_pulse_after_read) ;

property p_write_addr_followed_by_write_data;
  @(posedge clk) disable iff (!rst_n)
    (rx_valid && din[9:8] == 2'b00) |-> ##[1:$] (rx_valid && din[9:8] == 2'b01);
endproperty

a_write_addr_followed_by_write_data: assert property(p_write_addr_followed_by_write_data) ;

property p_read_addr_followed_by_read_data;
  @(posedge clk) disable iff (!rst_n)
    (rx_valid && din[9:8] == 2'b10) |-> ##[1:$] (rx_valid && din[9:8] == 2'b11);
endproperty

a_read_addr_followed_by_read_data: assert property(p_read_addr_followed_by_read_data) ;






endmodule
