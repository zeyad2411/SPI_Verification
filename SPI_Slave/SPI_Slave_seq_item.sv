package SPI_Slave_seq_item_pkg;
  import uvm_pkg::*;
  import shared_pkg::*;
  `include "uvm_macros.svh"

  class SPI_Slave_seq_item extends uvm_sequence_item;
    `uvm_object_utils(SPI_Slave_seq_item);

    // Randomized inputs
    logic MOSI;
    rand logic       rst_n, SS_n, tx_valid;
    rand logic [7:0] tx_data;
    
    // Outputs from DUT
    logic      [9:0] rx_data;
    logic            rx_valid, MISO;

    // Helper variables for constraints
    rand logic [10:0] mosi_bits;  // 11-bit array for MOSI serial data
    rand bit is_read_data;  // Flag to indicate if we're in READ_DATA operation
    
    // Static variable to track cycles across sequence items
    static int global_cycle_count = 0;

    function new(string name = "SPI_Slave_seq_item");
      super.new(name);
    endfunction

    // Constraint 1: Reset signal deasserted most of the time (95% probability)
    constraint rst_n_c {
      rst_n dist {1 := 95, 0 := 5};
    }

    // Constraint 3: First 3 bits of MOSI sequence must be valid combinations
    // Valid combinations: 000 (WRITE), 001 (invalid but handled), 110 (READ_ADD), 111 (READ_DATA)
    // For SPI protocol: bit 0 is command, sent first
    constraint mosi_valid_cmd_c {
      mosi_bits[10:8] inside {3'b000, 3'b001, 3'b110, 3'b111};
    }

    // Constraint 4: tx_valid high during READ_DATA operations
    constraint tx_valid_c {
      if (is_read_data && !SS_n) {
        tx_valid == 1;
      } else {
        tx_valid dist {0 := 70, 1 := 30};
      }
    }

    // Helper constraint for read data flag based on command
    constraint read_data_flag_c {
      if (mosi_bits[10:8] == 3'b111) {
        is_read_data == 1;
      } else {
        is_read_data == 0;
      }
    }

    // Constraint 2: SS_n timing control (handled in post_randomize)
    // For normal operations: high for 1 cycle every 13 cycles
    // For read data: high for 1 cycle every 23 cycles

    // Post randomize to handle SS_n timing and MOSI bit-by-bit driving
    function void post_randomize();
      // Constraint 2: SS_n control based on cycle count and operation type
      if (is_read_data) begin
        // For READ_DATA: SS_n high for 1 cycle every 23 cycles
        if (global_cycle_count % 23 == 0) begin
          SS_n = 1;
        end else begin
          SS_n = 0;
        end
      end else begin
        // For other operations: SS_n high for 1 cycle every 13 cycles
        if (global_cycle_count % 13 == 0) begin
          SS_n = 1;
        end else begin
          SS_n = 0;
        end
      end

      // Constraint 3: Drive MOSI bit by bit from mosi_bits array
      // The current bit to drive depends on the cycle within the transaction
      // When SS_n goes low (start of transaction), start from MSB (bit 10)
      if (SS_n == 0) begin
        int bit_index;
        bit_index = global_cycle_count % 11;  // Which bit to send (0-10)
        MOSI = mosi_bits[10 - bit_index];  // Send from MSB to LSB
      end else begin
        MOSI = 0;  // Default value when SS_n is high
      end

      // Increment global cycle counter
      global_cycle_count++;
      
      // Log the transaction details
      `uvm_info("SEQ_ITEM_POST_RAND", 
        $sformatf("Cycle: %0d, SS_n: %0b, MOSI: %0b, cmd_bits: %3b, is_read: %0b, tx_valid: %0b", 
        global_cycle_count, SS_n, MOSI, mosi_bits[10:8], is_read_data, tx_valid), UVM_HIGH);
    endfunction

    // Function to reset the global cycle counter (useful for test restart)
    static function void reset_cycle_count();
      global_cycle_count = 0;
    endfunction

    function string convert2string();
      return $sformatf("%s MOSI = 0b%0b, rst_n = %0b, SS_n = %0b, tx_valid = 0b%0b, tx_data = 0x%0h, rx_data = 0x%0h, rx_valid = 0b%0b, MISO = 0b%0b, mosi_bits = 0b%11b, cycle: %0d", 
        super.convert2string(), MOSI, rst_n, SS_n, tx_valid, 
        tx_data, rx_data, rx_valid, MISO, mosi_bits, global_cycle_count);
    endfunction

    function string convert2string_stimulus();
      return $sformatf("%s MOSI = 0b%0b, rst_n = %0b, SS_n = %0b, tx_valid = 0b%0b, tx_data = 0x%0h, cmd: %3b, is_read_data: %0b", 
        super.convert2string(), MOSI, rst_n, SS_n, tx_valid, 
        tx_data, mosi_bits[10:8], is_read_data);
    endfunction

  endclass
endpackage