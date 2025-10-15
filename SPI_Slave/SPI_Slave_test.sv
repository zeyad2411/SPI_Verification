package SPI_Slave_test_pkg;
import SPI_Slave_env_pkg::*;
import SPI_Slave_config_pkg::*;
import uvm_pkg::*;
import SPI_Slave_reset_seq_pkg::*;
import SPI_Slave_main_seq_pkg::*;
import shared_pkg::*;

`include "uvm_macros.svh"


class SPI_Slave_test extends uvm_test;
    `uvm_component_utils(SPI_Slave_test)
    
    SPI_Slave_env env;
    SPI_Slave_config SPI_Slave_cfg;
    virtual SPI_Slave_if SPI_Slave_vif;
    virtual SPI_gm_if SPI_gm_vif;
    SPI_Slave_main_seq main_seq;
    SPI_Slave_reset_seq reset_seq;

    function new(string name = "SPI_Slave_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = SPI_Slave_env::type_id::create("env", this);
        SPI_Slave_cfg = SPI_Slave_config::type_id::create("SPI_Slave_cfg", this);
        main_seq = SPI_Slave_main_seq::type_id::create("main_seq", this);
        reset_seq = SPI_Slave_reset_seq::type_id::create("reset_seq", this);

        if (!uvm_config_db #(virtual SPI_Slave_if)::get(this, "", "SPI_Slave_IF", SPI_Slave_vif))
            `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the SPI_Slave from the uvm_config_db")

        if (!uvm_config_db #(virtual SPI_gm_if)::get(this, "", "SPI_gm_IF", SPI_gm_vif))
            `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the SPI_gm from the uvm_config_db")    

        SPI_Slave_cfg.SPI_Slave_vif = SPI_Slave_vif;
        SPI_Slave_cfg.SPI_gm_vif = SPI_gm_vif;
        SPI_Slave_cfg.is_active = UVM_ACTIVE;
        uvm_config_db #(SPI_Slave_config)::set(this, "*", "CFG", SPI_Slave_cfg);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        
        //reset sequence
        `uvm_info("run_phase", "Reset Asserted", UVM_LOW)
        reset_seq.start(env.agt.sqr);
        `uvm_info("run_phase", "Reset Deasserted", UVM_LOW)

        //main sequence
        `uvm_info("run_phase", "Stimulus Generation Started", UVM_LOW)
        main_seq.start(env.agt.sqr);
        `uvm_info("run_phase", "Stimulus Generation Ended", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
endclass
endpackage