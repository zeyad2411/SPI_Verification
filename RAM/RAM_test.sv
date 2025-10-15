package RAM_test_pkg;
import RAM_env_pkg::*;
import RAM_config_pkg::*;
import uvm_pkg::*;
import RAM_reset_seq_pkg::*;
import RAM_read_seq_pkg::*;
import RAM_write_seq_pkg::*;
import RAM_write_read_seq_pkg::*;
import shared_pkg::*;

`include "uvm_macros.svh"


class RAM_test extends uvm_test;
    `uvm_component_utils(RAM_test)
    
    RAM_env env;
    RAM_config RAM_cfg;
    virtual RAM_if RAM_vif;
    RAM_write_seq w_seq;
    RAM_read_seq r_seq;
    RAM_write_read_seq w_r_seq;
    RAM_reset_seq reset_seq;

    function new(string name = "RAM_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = RAM_env::type_id::create("env", this);
        RAM_cfg = RAM_config::type_id::create("RAM_cfg", this);
        reset_seq = RAM_reset_seq::type_id::create("reset_seq", this);
        w_seq = RAM_write_seq::type_id::create("w_seq", this);
        r_seq = RAM_read_seq::type_id::create("r_seq", this);
        w_r_seq = RAM_write_read_seq::type_id::create("w_r_seq", this);

        if (!uvm_config_db #(virtual RAM_if)::get(this, "", "RAM_IF", RAM_vif))
            `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the RAM from the uvm_config_db")

        RAM_cfg.RAM_vif = RAM_vif;
        uvm_config_db #(RAM_config)::set(this, "*", "CFG", RAM_cfg);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        
        //reset sequence
        `uvm_info("run_phase", "Reset Asserted", UVM_LOW)
        reset_seq.start(env.agt.sqr);
        `uvm_info("run_phase", "Reset Deasserted", UVM_LOW)

        //write sequence
        `uvm_info("run_phase", "write Generation Started", UVM_LOW)
        w_seq.start(env.agt.sqr);
        `uvm_info("run_phase", "write Generation Ended", UVM_LOW)

        //read sequence
        `uvm_info("run_phase", "read Generation Started", UVM_LOW)
        r_seq.start(env.agt.sqr);
        `uvm_info("run_phase", "read Generation Ended", UVM_LOW)

        //write and read sequence
        `uvm_info("run_phase", "write and read Generation Started", UVM_LOW)
        w_r_seq.start(env.agt.sqr);
        `uvm_info("run_phase", "write and read Generation Ended", UVM_LOW)

        
        
        phase.drop_objection(this);
    endtask
endclass
endpackage