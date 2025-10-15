package SPI_Wrapper_env_pkg;

import SPI_Wrapper_seq_item_pkg::*;
import SPI_Wrapper_sequencer_pkg::*;
import SPI_Wrapper_agent_pkg::*;
import SPI_Wrapper_scoreboard_pkg::*;
import SPI_Wrapper_coverage_pkg::*;

import SPI_Slave_agent_pkg::*;
import SPI_Slave_scoreboard_pkg::*;
import SPI_Slave_coverage_pkg::*;

import RAM_agent_pkg::*;
import RAM_scoreboard_pkg::*;
import RAM_coverage_pkg::*;

import shared_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

class SPI_Wrapper_env extends uvm_env;
    `uvm_component_utils(SPI_Wrapper_env)

    SPI_Wrapper_agent wrapper_agt;
    SPI_Wrapper_scoreboard wrapper_sb;
    SPI_Wrapper_coverage wrapper_cov;

    function new(string name = "SPI_Wrapper_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //Wrapper handling
        wrapper_agt = SPI_Wrapper_agent::type_id::create("agt", this);
        wrapper_sb = SPI_Wrapper_scoreboard::type_id::create("sb", this);
        wrapper_cov = SPI_Wrapper_coverage::type_id::create("cov", this);

    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        wrapper_agt.agt_ap.connect(wrapper_sb.sb_export);
        wrapper_agt.agt_ap.connect(wrapper_cov.cov_export);
    endfunction
endclass
endpackage