package SPI_Slave_config_pkg;
import uvm_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"
class SPI_Slave_config extends uvm_object;
`uvm_object_utils(SPI_Slave_config);

virtual SPI_Slave_if SPI_Slave_vif;
virtual SPI_gm_if SPI_gm_vif; 
uvm_active_passive_enum is_active = UVM_ACTIVE;
function new(string name = "SPI_Slave_config");
  super.new(name);  
endfunction

endclass
    endpackage