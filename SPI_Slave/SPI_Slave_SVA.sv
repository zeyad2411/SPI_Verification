import shared_pkg::*;

module SPI_Slave_SVA (
    // Interface signals from the SPI Slave DUT
    input bit        clk,
    input logic      MOSI,
    input logic      tx_valid,
    input logic      tx_data,
    input logic      rst_n,
    input logic      SS_n,
    input logic [9:0] rx_data,
    input logic      rx_valid,
    input logic      MISO,
    // FSM current state from the DUT for checking transitions
    input logic [2:0] cs
);

//----------------------------------------------------------------------
// 1. RESET ASSERTION (VP Label 1)
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
// 2. TRANSACTION TIMING ASSERTIONS (VP Labels 2-5)
//    - Split into two assertions for precise 13-cycle and 23-cycle checks.
//----------------------------------------------------------------------
AP2_normal_op_timing_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    // Trigger: Entering a normal 13-cycle command state
    ( ($past(cs) != WRITE && cs == WRITE) || ($past(cs) != READ_ADD && cs == READ_ADD) )
    |=>
    // Consequence: rx_valid is high 9 cycles later, and SS_n rises 1 cycle after that.
    ##9 (rx_valid) ##1 $rose(SS_n)
) else $error("Normal Operation (13-cycle) Timing Assertion Failed.");

CP2_normal_op_timing_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    ( ($past(cs) != WRITE && cs == WRITE) || ($past(cs) != READ_ADD && cs == READ_ADD) )
);

AP3_read_data_op_timing_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    // Trigger: Entering the extended 23-cycle READ_DATA state
    ($past(cs) != READ_DATA && cs == READ_DATA)
    |=>
    // Consequence: rx_valid is high 9 cycles later, and SS_n rises 11 cycles after that.
    ##9 (rx_valid) ##11 $rose(SS_n)
) else $error("Read Data (23-cycle) Timing Assertion Failed.");

CP3_read_data_op_timing_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    ($past(cs) != READ_DATA && cs == READ_DATA)
);

//----------------------------------------------------------------------
// 4. SIGNAL INTEGRITY ASSERTIONS
//----------------------------------------------------------------------
AP4_miso_inactive_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    // When not actively transmitting data, MISO should be low
    (cs != READ_DATA) |-> (MISO == 1'b0)
) else $error("MISO Signal Integrity Failed: MISO was active outside of READ_DATA state.");

CP4_miso_inactive_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
      (cs != READ_DATA) |-> (MISO == 1'b0)
);

AP5_rx_data_stable_when_idle_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    // When SS_n is high (slave is idle), the rx_data bus should not change
    (SS_n && $past(SS_n)) |=> $stable(rx_data)
) else $error("rx_data Signal Integrity Failed: Data changed while slave was idle (SS_n high).");

CP5_rx_data_stable_when_idle_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (SS_n && $past(SS_n)) |=> $stable(rx_data)
);

//----------------------------------------------------------------------
// 5. FSM TRANSITION ASSERTIONS (VP Label 7)
//    - Guarded by conditional compilation macro "SIM".
//----------------------------------------------------------------------
`ifdef SIM

// --- LEGAL TRANSITIONS: Checks that from any state, the FSM only moves to a valid next state ---
AP6_fsm_legal_transition_from_idle_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == IDLE) |-> ##1 (cs == IDLE || cs == CHK_CMD)
) else $error("FSM Illegal Transition: Invalid next state from IDLE.");

CP6_fsm_legal_transition_from_idle_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == IDLE) |-> ##1 (cs == IDLE || cs == CHK_CMD)
);

AP7_fsm_legal_transition_from_chk_cmd_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == CHK_CMD) |-> ##1 (cs inside {IDLE, WRITE, READ_ADD, READ_DATA})
) else $error("FSM Illegal Transition: Invalid next state from CHK_CMD.");

CP7_fsm_legal_transition_from_chk_cmd_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == CHK_CMD) |-> ##1 (cs inside {IDLE, WRITE, READ_ADD, READ_DATA})
);

AP8_fsm_legal_transition_from_write_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == WRITE) |-> ##1 (cs == WRITE || cs == IDLE)
) else $error("FSM Illegal Transition: Invalid next state from WRITE.");

CP8_fsm_legal_transition_from_write_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == WRITE) |-> ##1 (cs == WRITE || cs == IDLE)
);

AP9_fsm_legal_transition_from_read_add_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == READ_ADD) |-> ##1 (cs == READ_ADD || cs == IDLE)
) else $error("FSM Illegal Transition: Invalid next state from READ_ADD.");

CP9_fsm_legal_transition_from_read_add_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == READ_ADD) |-> ##1 (cs == READ_ADD || cs == IDLE)
);

AP10_fsm_legal_transition_from_read_data_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == READ_DATA) |-> ##1 (cs == READ_DATA || cs == IDLE)
) else $error("FSM Illegal Transition: Invalid next state from READ_DATA.");

CP10_fsm_legal_transition_from_read_data_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == READ_DATA) |-> ##1 (cs == READ_DATA || cs == IDLE)
);

// --- SPECIFIC TRANSITIONS: Checks for specific valid cause-and-effect transitions ---
AP11_fsm_idle_to_chk_cmd_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == IDLE && !SS_n) |-> ##1 (cs == CHK_CMD)
) else $error("FSM Error: Did not transition from IDLE to CHK_CMD when SS_n fell.");

CP11_fsm_idle_to_chk_cmd_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == IDLE && !SS_n) |-> ##1 (cs == CHK_CMD)
);

AP12_fsm_cmd_to_idle_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs inside {WRITE, READ_ADD, READ_DATA} && SS_n) |-> ##1 (cs == IDLE)
) else $error("FSM Error: Did not transition from a command state to IDLE when SS_n rose.");

CP12_fsm_cmd_to_idle_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs inside {WRITE, READ_ADD, READ_DATA} && SS_n) |-> ##1 (cs == IDLE)
);

AP13_fsm_chk_cmd_aborted_to_idle_assert: assert property (
    @(posedge clk) disable iff (!rst_n)
    (cs == CHK_CMD && $rose(SS_n)) |-> ##1 (cs == IDLE)
) else $error("FSM Error: Did not return to IDLE when transaction was aborted in CHK_CMD state.");

CP13_fsm_chk_cmd_aborted_to_idle_cover: cover property (
    @(posedge clk) disable iff (!rst_n)
    (cs == CHK_CMD && $rose(SS_n)) |-> ##1 (cs == IDLE)
);

`endif // SIM

endmodule
