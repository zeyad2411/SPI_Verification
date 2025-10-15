package SPI_Wrapper_config_pkg;
import uvm_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"
class SPI_Wrapper_config extends uvm_object;
`uvm_object_utils(SPI_Wrapper_config);

virtual SPI_Wrapper_if SPI_Wrapper_vif; 
virtual SPI_Wrapper_GM_if SPI_Wrapper_GM_vif;
uvm_active_passive_enum is_active = UVM_ACTIVE;
function new(string name = "SPI_config_config");
  super.new(name);  
endfunction

endclass
    endpackage