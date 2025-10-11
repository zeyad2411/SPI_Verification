package SPI_Slave_env_pkg;
import SPI_Slave_agent_pkg::*;
import SPI_Slave_scoreboard_pkg::*;
import SPI_Slave_coverage_pkg::*;
import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

class SPI_Slave_env extends uvm_env;
    `uvm_component_utils(SPI_Slave_env)

    SPI_Slave_agent agt;
    SPI_Slave_scoreboard sb;
    SPI_Slave_coverage cov;

    function new(string name = "SPI_Slave_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = SPI_Slave_agent::type_id::create("agt", this);
        sb = SPI_Slave_scoreboard::type_id::create("sb", this);
        cov = SPI_Slave_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.agt_ap.connect(sb.sb_export);
        agt.agt_ap.connect(cov.cov_export);
    endfunction
endclass
endpackage