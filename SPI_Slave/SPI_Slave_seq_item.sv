package SPI_Slave_seq_item_pkg;
  import uvm_pkg::*;
  import shared_pkg::*;
  `include "uvm_macros.svh"

  class SPI_Slave_seq_item extends uvm_sequence_item;
    `uvm_object_utils(SPI_Slave_seq_item)

    // ============================================
    // DUT signals
    // ============================================
    logic MOSI;
    rand logic       rst_n, SS_n, tx_valid;
    rand logic [7:0] tx_data;

    // DUT outputs (for monitor use)
    logic [9:0] rx_data;
    logic       rx_valid;
    logic       MISO;

    // ============================================
    // Internal randomization control
    // ============================================
    rand logic [10:0] mosi_bits;  // full serial frame (11 bits)
    rand bit is_read_data;        // used to control tx_valid logic

    // Global (shared) variables for frame control
    static int global_cycle_count = 0;
    static int bit_counter = 0;
    static logic [10:0] current_mosi_bits; // current active command frame
    static int current_period;
    static bit current_is_read_data;

    // ============================================
    // Constructor
    // ============================================
    function new(string name = "SPI_Slave_seq_item");
      super.new(name);
    endfunction

    // ============================================
    // Constraints
    // ============================================

    // (1) Reset mostly deasserted
    constraint rst_n_c {
      rst_n dist {1 := 95, 0 := 5};
    }

    // (2) Valid MOSI command combinations (first 3 bits)
    // Commands: 000=WRITE_ADD, 001=reserved, 110=READ_ADD, 111=READ_DATA
    constraint valid_cmd_c {
      mosi_bits[10:8] inside {3'b000, 3'b001, 3'b110, 3'b111};
    }

    // (3) Define read_data flag for tx_valid control
    constraint read_data_flag_c {
      if (mosi_bits[10:8] == 3'b111)
        is_read_data == 1;
      else
        is_read_data == 0;
    }

    // (4) tx_valid high only during READ_DATA operations
    constraint tx_valid_c {
      if (is_read_data)
        tx_valid == 1;
      else
        tx_valid == 0;
    }

    // ============================================
    // post_randomize() : handle SS_n + MOSI timing
    // ============================================
    function void post_randomize();

      // Latch new frame properties only at frame start
if (bit_counter == 0) begin
  current_is_read_data = is_read_data;
  current_period       = current_is_read_data ? 23 : 13;
  current_mosi_bits    = mosi_bits;   // latch full command frame
end
else begin
  mosi_bits = current_mosi_bits;      // reuse ongoing frame
end

// SS_n timing — high for 1 cycle at start of each frame
    if (bit_counter == 0)
      SS_n = 1;
    else
     SS_n = 0;

      // (3) Determine current bit to transmit (MSB first)
     
      if (SS_n == 0)
        MOSI = mosi_bits[10 - bit_counter];
      else
        MOSI = 0; // idle value

      // (4) tx_valid logic (reinforced for safety)
      if (mosi_bits[10:8] == 3'b111)
        tx_valid = 1;

      // Increment counters
      bit_counter++;
      global_cycle_count++;

      if (bit_counter == 11)
        bit_counter = 0; // start next frame

      // Debug print
      `uvm_info("POST_RANDOMIZE",
        $sformatf("Cycle=%0d | Bit=%0d | SS_n=%0b | MOSI=%0b | CMD=%3b | tx_valid=%0b | rst_n=%0b",
          global_cycle_count, bit_counter, SS_n, MOSI, mosi_bits[10:8], tx_valid, rst_n),
        UVM_HIGH)
    endfunction

    // ============================================
    // Utility functions
    // ============================================

    static function void reset_cycle_count();
      global_cycle_count = 0;
      bit_counter = 0;
    endfunction

    function string convert2string();
      return $sformatf("MOSI=%0b SS_n=%0b rst_n=%0b tx_valid=%0b tx_data=0x%0h mosi_bits=%b (cycle=%0d bit=%0d)",
        MOSI, SS_n, rst_n, tx_valid, tx_data, mosi_bits, global_cycle_count, bit_counter);
    endfunction

    function string convert2string_stimulus();
      return $sformatf("Stimulus: CMD=%3b MOSI=%0b SS_n=%0b tx_valid=%0b rst_n=%0b tx_data=0x%0h",
        mosi_bits[10:8], MOSI, SS_n, tx_valid, rst_n, tx_data);
    endfunction

  endclass
endpackage