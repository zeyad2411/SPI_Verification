import shared_pkg::*;

module SPI_Slave_SVA (
    input bit        clk,
    input logic      MOSI,
    input logic      tx_valid,
    input logic [9:0] tx_data,        // Changed from single bit to [9:0]
    input logic      rst_n,
    input logic      SS_n,
    input logic [9:0] rx_data,
    input logic      rx_valid,
    input logic      MISO,
    input logic [2:0] cs_sva
);

//----------------------------------------------------------------------
// 1. RESET ASSERTION
//----------------------------------------------------------------------
AP1_reset_outputs_low_assert: assert property (
    @(posedge clk)
    !rst_n |=> (MISO == 1'b0 && rx_valid == 1'b0 && rx_data == '0)
) else $error("Reset Assertion Failed: Outputs were not low during reset.");

CP1_reset_outputs_low_cover: cover property (
    @(posedge clk)
    !rst_n |=> (MISO == 1'b0 && rx_valid == 1'b0 && rx_data == '0)
);

//----------------------------------------------------------------------
// 2. STATE TRANSITION ASSERTIONS
//----------------------------------------------------------------------

// IDLE to CHK_CMD transition when SS_n goes low
AP2_idle_to_chk_cmd_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    ( ($past(SS_n) == 1 && SS_n == 0)  && cs_sva == IDLE ) |=> (cs_sva == CHK_CMD)
) else $error("FSM Error: Did not transition from IDLE to CHK_CMD when SS_n fell.");

CP2_idle_to_chk_cmd_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == IDLE && !SS_n && $past(SS_n)) |=> (cs_sva == CHK_CMD)
);

// CHK_CMD must transition to a valid state or stay in CHK_CMD
AP3_chk_cmd_valid_next_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == CHK_CMD) |=> (cs_sva inside {IDLE, CHK_CMD, WRITE, READ_ADD, READ_DATA})
) else $error("FSM Error: CHK_CMD transitioned to invalid state.");

CP3_chk_cmd_valid_next_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == CHK_CMD) |=> (cs_sva inside {IDLE, CHK_CMD, WRITE, READ_ADD, READ_DATA})
);

// WRITE state: stay in WRITE when SS_n is low, go to IDLE when SS_n goes high
AP4_write_state_behavior_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == WRITE) |=> (cs_sva inside {WRITE, IDLE})
) else $error("FSM Error: Invalid transition from WRITE state.");

CP4_write_state_behavior_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == WRITE)
);

// READ_ADD state: stay in READ_ADD when SS_n is low, go to IDLE when SS_n goes high
AP5_read_add_state_behavior_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == READ_ADD) |=> (cs_sva inside {READ_ADD, IDLE})
) else $error("FSM Error: Invalid transition from READ_ADD state.");

CP5_read_add_state_behavior_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == READ_ADD)
);

// READ_DATA state: stay in READ_DATA when SS_n is low, go to IDLE when SS_n goes high
AP6_read_data_state_behavior_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == READ_DATA) |=> (cs_sva inside {READ_DATA, IDLE})
) else $error("FSM Error: Invalid transition from READ_DATA state.");

CP6_read_data_state_behavior_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == READ_DATA)
);

// Any command state (WRITE, READ_ADD, READ_DATA) must return to IDLE when SS_n rises
AP7_cmd_to_idle_on_ss_n_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva inside {WRITE, READ_ADD, READ_DATA} && SS_n) |=> (cs_sva == IDLE)
) else $error("FSM Error: Did not return to IDLE when SS_n rose during command state.");

CP7_cmd_to_idle_on_ss_n_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva inside {WRITE, READ_ADD, READ_DATA} && SS_n) |=> (cs_sva == IDLE)
);





//----------------------------------------------------------------------
// 3. OUTPUT SIGNAL BEHAVIOR ASSERTIONS
//----------------------------------------------------------------------

// rx_valid should be low in IDLE state
AP8_idle_rx_valid_low_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == IDLE) |-> (!rx_valid)
) else $error("Output Error: rx_valid was high in IDLE state.");

CP8_idle_rx_valid_low_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == IDLE) |-> (!rx_valid)
);

// rx_valid pulses should be single-cycle (if high, should go low next cycle)
AP9_rx_valid_single_cycle_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (rx_valid && !$past(SS_n)) |=> (!rx_valid || SS_n)
) else $error("Output Error: rx_valid was not a single-cycle pulse.");

CP9_rx_valid_single_cycle_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (rx_valid && !$past(SS_n))
);

// rx_data should remain stable when rx_valid is low and not in active transaction
AP10_rx_data_stable_when_idle_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (SS_n && $past(SS_n) && !rx_valid && !$past(rx_valid)) |=> $stable(rx_data)
) else $error("Output Error: rx_data changed while idle and rx_valid was low.");

CP10_rx_data_stable_when_idle_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (SS_n && $past(SS_n) && !rx_valid && !$past(rx_valid))
);

//----------------------------------------------------------------------
// 4. MISO SIGNAL BEHAVIOR ASSERTIONS
//----------------------------------------------------------------------



// MISO behavior during READ_DATA with tx_valid
AP11_miso_tx_valid_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == READ_DATA && tx_valid) |-> (MISO == tx_data[0] || MISO == tx_data[1] || 
                                             MISO == tx_data[2] || MISO == tx_data[3] || 
                                             MISO == tx_data[4] || MISO == tx_data[5] || 
                                             MISO == tx_data[6] || MISO == tx_data[7] ||
                                             MISO == tx_data[8] || MISO == tx_data[9])
) else $error("MISO Error: MISO value doesn't match any bit of tx_data during transmission.");

CP11_miso_tx_valid_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs_sva == READ_DATA && tx_valid)
);

//----------------------------------------------------------------------
// 5. PROTOCOL TIMING ASSERTIONS
//----------------------------------------------------------------------

// rx_valid should only assert during active transactions (SS_n low)
AP12_rx_valid_only_when_active_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (rx_valid) |-> (!SS_n || $past(!SS_n))
) else $error("Protocol Error: rx_valid asserted when SS_n was high.");

CP12_rx_valid_only_when_active_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (rx_valid)
);

// When transitioning from command state to IDLE, rx_valid should go low
AP13_rx_valid_low_on_idle_transition_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    ($past(cs_sva) inside {WRITE, READ_ADD, READ_DATA} && cs_sva == IDLE) |-> (!rx_valid)
) else $error("Protocol Error: rx_valid was high when entering IDLE from command state.");

CP13_rx_valid_low_on_idle_transition_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    ($past(cs_sva) inside {WRITE, READ_ADD, READ_DATA} && cs_sva == IDLE)
);

//----------------------------------------------------------------------
// 6. FSM STATE VALIDITY (Optional with SIM macro)
//----------------------------------------------------------------------
`ifdef SIM

// FSM should only be in valid states
AP14_fsm_valid_states_only_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    cs_sva inside {IDLE, CHK_CMD, WRITE, READ_ADD, READ_DATA}
) else $error("FSM Error: FSM entered an invalid state.");

CP14_fsm_valid_states_only_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    cs_sva inside {IDLE, CHK_CMD, WRITE, READ_ADD, READ_DATA}
);

// Reset should force FSM to IDLE
AP15_reset_forces_idle_assert: assert property (
    @(posedge clk)
    !rst_n |=> (cs_sva == IDLE)
) else $error("FSM Error: FSM was not in IDLE state after reset.");

CP15_reset_forces_idle_cover: cover property (
    @(posedge clk)
    !rst_n |=> (cs_sva == IDLE)
);

`endif // SIM

endmodule