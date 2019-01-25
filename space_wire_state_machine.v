//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_state_machine
(
  input    wire        i_clk,
  input    wire        i_rx_clk,
  input    wire        i_reset,
  input    wire        i_after_12p8_us,
  input    wire        i_after_6p4_us,
  input    wire        i_link_start,
  input    wire        i_link_disable,
  input    wire        i_auto_start,
  output   wire        o_tx_en,
  output   wire        o_send_nulls,
  output   wire        o_send_fcts,
  output   wire        o_send_n_character,
  output   wire        o_send_time_codes,
  input    wire        i_got_fct,
  input    wire        i_got_time_code,
  input    wire        i_got_n_character,
  input    wire        i_got_null,
  input    wire        i_got_bit,
  input    wire        i_credit_error,
  input    wire        i_rx_error,
  output   wire        o_rx_en,
  output   wire        o_char_sequence_error,
  output   wire        o_space_wire_reset_out,
  input    wire        i_fifo_available,
  output   wire        o_timer_6p4_us_reset,
  output   wire        o_timer_12p8_us_start,
  output   wire        o_link_up_transition_sync,
  output   wire        o_link_down_transition_sync,
  output   wire        o_link_up_en,
  output   wire        o_null_sync,
  output   wire        o_fct_sync
);
//------------------------------------------------------------------------------
// TYPE linkStateMachine:
localparam SLSM_ERROR_RESET  = 0;
localparam SLSM_ERROR_WAIT   = 1;
localparam SLSM_READY        = 2;
localparam SLSM_STARTED      = 3;
localparam SLSM_CONNECTING   = 4;
localparam SLSM_RUN          = 5;
//------------------------------------------------------------------------------
reg     [2:0] link_state;
wire    got_null_sync;
wire    got_fct_sync;
wire    got_time_code_sync;
wire    got_n_char_sync;
wire    async_error;
wire    rx_errors_sync;
reg     char_sequence_error;
reg     tx_en;
reg     send_nulls;
reg     send_fcts;
reg     send_n_char;
reg     send_time_code;
reg     rx_en;
reg     space_wire_reset_out;
reg     timer_6p4_us_reset;
reg     timer_12p8_us_reset;
//------------------------------------------------------------------------------
reg     link_up_transition;
reg     link_down_transition;
reg     link_up_en;
wire    credit_sync;
//------------------------------------------------------------------------------
assign async_error    = rx_errors_sync;
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst0_gotNullPulse
(
  .i_clk                   ( i_clk         ),
  .i_async_clk             ( i_rx_clk      ),
  .i_reset                 ( i_reset       ),
  .i_async_in              ( i_got_null    ),
  .o_sync_out              ( got_null_sync )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst1_gotFCTPulse
(
  .i_clk                   ( i_clk        ),
  .i_async_clk             ( i_rx_clk     ),
  .i_reset                 ( i_reset      ),
  .i_async_in              ( i_got_fct    ),
  .o_sync_out              ( got_fct_sync )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst2_gotTimeCodePulse
(
  .i_clk                   ( i_clk              ),
  .i_async_clk             ( i_rx_clk           ),
  .i_reset                 ( i_reset            ),
  .i_async_in              ( i_got_time_code    ),
  .o_sync_out              ( got_time_code_sync )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst3_gotNCharacterPulse
(
  .i_clk                   ( i_clk             ),
  .i_async_clk             ( i_rx_clk          ),
  .i_reset                 ( i_reset           ),
  .i_async_in              ( i_got_n_character ),
  .o_sync_out              ( got_n_char_sync   )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst4_errorPulse
(
  .i_clk                   ( i_clk          ),
  .i_async_clk             ( i_rx_clk       ),
  .i_reset                 ( i_reset        ),
  .i_async_in              ( i_rx_error     ),
  .o_sync_out              ( rx_errors_sync )
);
//------------------------------------------------------------------------------
assign o_char_sequence_error           = char_sequence_error;
assign o_tx_en                         = tx_en;
assign o_send_nulls                    = send_nulls;
assign o_send_fcts                     = send_fcts;
assign o_send_n_character              = send_n_char;
assign o_send_time_codes               = send_time_code;
assign o_rx_en                         = rx_en;
assign o_space_wire_reset_out          = space_wire_reset_out;
assign o_timer_6p4_us_reset            = timer_6p4_us_reset;
assign o_timer_12p8_us_start           = timer_12p8_us_reset;
assign o_link_up_transition_sync       = link_up_transition;
assign o_link_down_transition_sync     = link_down_transition;
assign o_link_up_en                    = link_up_en;
assign o_null_sync                     = got_null_sync;
assign o_fct_sync                      = got_fct_sync;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.4.6   StateMachine.
// ECSS-E-ST-50-12C 8.5.3.7 RxErr.
// ECSS-E-ST-50-12C 8.5.3.8 CreditError.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge i_credit_error)
  begin : s_link_state
    if ( i_reset | i_credit_error )
      begin
        link_state                     <= SLSM_ERROR_RESET;
        space_wire_reset_out           <= 1'b1;
        rx_en                          <= 1'b0;
        tx_en                          <= 1'b0;
        send_nulls                     <= 1'b0;
        send_fcts                      <= 1'b0;
        send_n_char                    <= 1'b0;
        send_time_code                 <= 1'b0;
        char_sequence_error            <= 1'b0;
        timer_6p4_us_reset             <= 1'b1;
        timer_12p8_us_reset            <= 1'b0;
        link_down_transition           <= 1'b0;
        link_up_transition             <= 1'b0;
        link_up_en                     <= 1'b0;
      end
    else
      begin
        case (link_state)
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.2.2 ErrorReset.
        // When the i_reset signal is de-asserted the ErrorReset state shall be 
        // left unconditionally after a delay of 6,4 us (nominal) and the state
        // machine shall move to the ErrorWait state.
        //======================================================================
        SLSM_ERROR_RESET:
          begin
            link_up_en                 <= 1'b0;
           
            if ( send_time_code )
              begin
                link_down_transition   <= 1'b1;
              end
            else
              begin
                link_down_transition   <= 1'b0;
              end
            if ( i_fifo_available )
              begin
                timer_6p4_us_reset     <= 1'b0;
              end
            space_wire_reset_out       <= 1'b1;
            rx_en                      <= 1'b0;
            tx_en                      <= 1'b0;
            send_nulls                 <= 1'b0;
            send_fcts                  <= 1'b0;
            send_n_char                <= 1'b0;
            send_time_code             <= 1'b0;
            char_sequence_error        <= 1'b0;
            if ( rx_errors_sync )
              begin
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_after_6p4_us )
              begin
                timer_12p8_us_reset    <= 1'b1;
                link_state             <= SLSM_ERROR_WAIT;
              end
          end
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.2.3 ErrorWait.
        // The ErrorWait state shall be left unconditionally after a delay 
        // of 12,8 us (nominal) and the state machine shall move 
        // to the Ready state.
        // If, while in the ErrorWait state, a disconnection error is 
        // detected the state machine shall move back 
        // to the ErrorReset state.
        //======================================================================
        SLSM_ERROR_WAIT:
          begin
            space_wire_reset_out       <= 1'b0;
            timer_12p8_us_reset        <= 1'b0;
            rx_en                      <= 1'b1;
            if ( rx_errors_sync )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( got_time_code_sync | got_fct_sync | got_n_char_sync )
              begin
                char_sequence_error    <= 1'b1;
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_after_12p8_us )
              begin
                link_state             <= SLSM_READY;
              end
          end
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.2.4 Ready.
        // The state machine shall wait in the Ready state until 
        // the [Link Enabled] guard becomes true and then it shall move on 
        // into the Started state.
        // If, while in the Ready state, a disconnection error is detected, 
        // or if after thegotNULL condition is set, a parity error or escape
        // error occurs, or any character other than a NULL is received, 
        // then the state machine shall move to the ErrorReset state.
        //======================================================================
        SLSM_READY:
          begin
            rx_en <= 1'b1;
            if ( rx_errors_sync )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( got_fct_sync | got_n_char_sync | got_time_code_sync )
              begin
                char_sequence_error    <= 1'b1;
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_auto_start & got_null_sync )
              begin
                timer_12p8_us_reset    <= 1'b1;
                link_state             <= SLSM_STARTED;
              end
            else if ( i_link_start )
              begin
                timer_12p8_us_reset    <= 1'b1;
                link_state             <= SLSM_STARTED;
              end
          end
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.2.5 Started.
        // The state machine shall move to the Connecting state if the gotNULL
        // condition is set.
        // If, while in the Started state, a disconnection error is detected, 
        // or if after the gotNULL condition is set, a parity error or escape 
        // error occurs, or any character other than a NULL is received, then 
        // the state machine shall move to the ErrorReset state.
        //======================================================================
        SLSM_STARTED:
          begin
            tx_en                      <= 1'b1;
            rx_en                      <= 1'b1;
            send_nulls                 <= 1'b1;
            timer_12p8_us_reset        <= 1'b0;
            if ( rx_errors_sync )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_link_disable )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( got_fct_sync | got_n_char_sync | got_time_code_sync )
              begin
                char_sequence_error    <= 1'b1;
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_after_12p8_us )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( got_null_sync )
              begin
                timer_12p8_us_reset    <= 1'b1;
                link_state             <= SLSM_CONNECTING;
              end
          end
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.2.6 Connecting
        // If an FCT is received (gotFCT condition true) the state machine shall
        // move to the Run state.
        // If, while in the Connecting state, a disconnect error, parity error 
        // or escape error is detected, or if any character other than NULL or 
        // FCT is received, then the state machine shall move to the ErrorReset 
        // state.
        //======================================================================
        SLSM_CONNECTING:
          begin
            timer_12p8_us_reset        <= 1'b0;
            tx_en                      <= 1'b1;
            rx_en                      <= 1'b1;
            send_fcts                  <= 1'b1;
            if ( rx_errors_sync )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_link_disable )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( i_after_12p8_us )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( got_n_char_sync )
              begin
                char_sequence_error    <= 1'b1;
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
            else if ( got_fct_sync )
              begin
                link_state             <= SLSM_RUN;
              end
          end
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.2.7 Run
        // In the Run state the receiver is enabled and the transmitter is 
        // enabled to send Time-Codes, FCTs, N-Chars and NULLs.
        // If  a disconnection error, parity error, ESC error occur, then the 
        // state machine shall move to the ErrorResetState.
        //======================================================================
        SLSM_RUN:
          begin
            tx_en                      <= 1'b1;
            rx_en                      <= 1'b1;
            send_n_char                <= 1'b1;
            send_time_code             <= 1'b1;
            link_up_en                 <= 1'b1;
            if ( !send_time_code )
              begin
                link_up_transition     <= 1'b1;
              end
            else
              begin
                link_up_transition     <= 1'b0;
              end
            if ( i_link_disable | rx_errors_sync )
              begin
                timer_6p4_us_reset     <= 1'b1;
                link_state             <= SLSM_ERROR_RESET;
              end
          end
        default:
          begin
            link_state                 <= SLSM_ERROR_RESET;
          end
        endcase
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_state_machine

