package SPI_Wrapper_test_pkg;
    import shared_pkg::*;
    import SPI_Wrapper_config_pkg::*;
    import SPI_Slave_config_pkg::*;
    import RAM_config_pkg::*;
    import RAM_env_pkg::*;
    import SPI_Slave_env_pkg::*;
    import SPI_Wrapper_env_pkg::*;
    import SPI_Wrapper_rst_seq_pkg::*;
    import SPI_Wrapper_read_seq_pkg::*;
    import SPI_Wrapper_write_seq_pkg::*;
    import SPI_Wrapper_write_read_seq_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    class SPI_Wrapper_test extends uvm_test;
        `uvm_component_utils(SPI_Wrapper_test)

        // Environment objects - ADD MISSING DECLARATIONS
        SPI_Wrapper_env env;
        SPI_Slave_env slave_env;    
        RAM_env ram_env;             

        // Virtual interfaces
        virtual SPI_Wrapper_if SPI_Wrapper_vif; 
        virtual SPI_Wrapper_GM_if SPI_Wrapper_GM_vif;
        virtual SPI_gm_if SPI_gm_vif;
        virtual SPI_Slave_if SPI_Slave_vif;
        virtual RAM_if RAM_vif;

        // Configuration objects
        SPI_Wrapper_config SPI_Wrapper_cfg;
        SPI_Slave_config SPI_Slave_cfg;
        RAM_config RAM_cfg;

        // Sequences
        SPI_Wrapper_rst_seq rst_seq; 
        SPI_Wrapper_read_seq read_seq; 
        SPI_Wrapper_write_seq write_seq; 
        SPI_Wrapper_write_read_seq write_read_seq; 

        // Construction function
        function new(string name = "SPI_Wrapper_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build both environment, sequences and configuration objects 
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            // Building environments - FIXED
            env = SPI_Wrapper_env::type_id::create("SPI_Wrapper_env", this);
            slave_env = SPI_Slave_env::type_id::create("SPI_Slave_env", this);
            ram_env = RAM_env::type_id::create("RAM_env", this);

            // Building configuration objects
            RAM_cfg = RAM_config::type_id::create("RAM_cfg");
            SPI_Slave_cfg = SPI_Slave_config::type_id::create("SPI_Slave_cfg");
            SPI_Wrapper_cfg = SPI_Wrapper_config::type_id::create("SPI_Wrapper_cfg");
            
            // Sequences creation - FIXED CLASS NAMES
            rst_seq = SPI_Wrapper_rst_seq::type_id::create("rst_seq", this);
            read_seq = SPI_Wrapper_read_seq::type_id::create("read_seq", this);
            write_seq = SPI_Wrapper_write_seq::type_id::create("write_seq", this);
            write_read_seq = SPI_Wrapper_write_read_seq::type_id::create("write_read_seq", this);

            // Getting the real interface and assign it to the virtual one in the configuration object
            // RAM
            if (!uvm_config_db #(virtual RAM_if)::get(this,"","RAM_V", RAM_cfg.RAM_vif))
                `uvm_fatal("build_phase", "test unable to get RAM_V interface");
            RAM_cfg.is_active = UVM_PASSIVE; // RAM Agent is passive agent
            // Setting the entire object to be visible by all under the SPI_Wrapper_test umbrella
            uvm_config_db #(RAM_config)::set(this,"*","CFG_R", RAM_cfg);
            
            // SPI Slave
            if (!uvm_config_db #(virtual SPI_Slave_if)::get(this,"","SPI_Slave_V", SPI_Slave_cfg.SPI_Slave_vif))
                `uvm_fatal("build_phase", "test unable to get SPI_Slave_V interface");
            
            if (!uvm_config_db #(virtual SPI_gm_if)::get(this, "", "SPI_gm_IF", SPI_Slave_cfg.SPI_gm_vif))
                `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the SPI_gm from the uvm_config_db");

            SPI_Slave_cfg.is_active = UVM_PASSIVE; // SPI Slave Agent is passive agent
            // Setting the entire object to be visible by all under the SPI_Wrapper_test umbrella
            uvm_config_db #(SPI_Slave_config)::set(this,"*","CFG_S", SPI_Slave_cfg);
            
            // SPI Wrapper
            if (!uvm_config_db #(virtual SPI_Wrapper_if)::get(this,"","SPI_Wrapper_V", SPI_Wrapper_cfg.SPI_Wrapper_vif))
                `uvm_fatal("build_phase", "test unable to get SPI_Wrapper_V interface");

            if (!uvm_config_db #(virtual SPI_Wrapper_GM_if)::get(this, "", "SPI_Wrapper_GM_V", SPI_Wrapper_cfg.SPI_Wrapper_GM_vif))
                `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the SPI_Wrapper_GM from the uvm_config_db");
            
            SPI_Wrapper_cfg.is_active = UVM_ACTIVE;
            // Setting the entire object to be visible by all under the SPI_Wrapper_test umbrella
            // FIXED: Use SPI_Wrapper_config instead of SPI_Wrapper_config_obj
            uvm_config_db #(SPI_Wrapper_config)::set(this,"*","CFG_W", SPI_Wrapper_cfg);
        endfunction
        
        // Run phase
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            phase.raise_objection(this); // Increment static var.
            
            // Reset sequence
            `uvm_info("run_phase", "reset asserted", UVM_LOW)
            rst_seq.start(env.wrapper_agt.sqr);
            `uvm_info("run_phase", "reset deasserted", UVM_LOW)

            // Write sequence
            `uvm_info("run_phase", "write asserted", UVM_MEDIUM)
            write_seq.start(env.wrapper_agt.sqr);
            `uvm_info("run_phase", "write deasserted", UVM_LOW)

            // Read sequence
            `uvm_info("run_phase", "read asserted", UVM_MEDIUM)
            read_seq.start(env.wrapper_agt.sqr);
            `uvm_info("run_phase", "read deasserted", UVM_LOW)

            

            // Write-read sequence
            `uvm_info("run_phase", "write_read asserted", UVM_MEDIUM)
            write_read_seq.start(env.wrapper_agt.sqr);
            `uvm_info("run_phase", "write_read deasserted", UVM_LOW)
            
            phase.drop_objection(this); // Decrement static var.
        endtask
    endclass: SPI_Wrapper_test
endpackage