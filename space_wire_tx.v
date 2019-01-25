//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_tx 
#(
  parameter      C_TX_CLK_DIVIDE_VAL      = 6'b001001
)
(
  input    wire                 i_tx_clk,
  input    wire                 i_clk,
  input    wire                 i_rx_clk,
  input    wire                 i_reset,
  output   wire                 o_space_wire_data_out,
  output   wire                 o_space_wire_strobe_out,
  input    wire                 i_tick_in,
  input    wire    [5:0]        i_time_in,
  input    wire    [1:0]        i_control_flags_in,
  input    wire                 i_tx_data_en,
  input    wire    [7:0]        i_tx_data,
  input    wire                 i_tx_data_control_flag,
  output   wire                 o_tx_ready,
  input    wire                 i_tx_en,
  input    wire                 i_send_nulls,
  input    wire                 i_send_fcts,
  input    wire                 i_send_n_char,
  input    wire                 i_send_time_codes,
  input    wire                 i_got_fct,
  input    wire                 i_got_n_char,
  input    wire    [5:0]        i_rx_fifo_count,
  output   wire                 o_credit_error,
  input    wire    [5:0]        i_tx_clk_divide,
  output   wire    [5:0]        o_credit_count_out,
  output   wire    [5:0]        o_outstanding_count_out,
  input    wire                 i_space_wire_reset,
  output   wire                 o_tx_eep_async,
  output   wire                 o_tx_eop_async,
  output   wire                 o_tx_byte_async
);
//------------------------------------------------------------------------------
// TYPE transmitStateMachine:
localparam SM_STOP     = 0;
localparam SM_PARITY   = 1;
localparam SM_CONTROL  = 2;
localparam SM_DATA     = 3;
//------------------------------------------------------------------------------
reg     [1:0]        state_tx;
reg     [5:0]        divide_count;
reg                  divide_state;
reg                  tx_parity;
reg                  null_send;
reg                  time_code_send;
reg                  data_out_reg;
reg                  strobe_out_reg;
reg                  send_start;
reg                  send_done;
reg     [8:0]        send_data;
reg     [3:0]        send_count;
wire                 tx_data_en_sync;
reg                  decrement_credit;
reg                  tx_fct_start;
reg                  tx_fct_done;
wire                 tick_in_sync;
reg                  tx_time_code_start;
reg                  tx_time_code_done;
reg                  tx_time_code_state;
wire                 got_n_char_sync;
reg     [9:0]        got_n_char_sync_delay;
reg     [5:0]        outstanding_count;
reg     [5:0]        rx_fifo_count_buffer0;
reg     [5:0]        rx_fifo_count_buffer1;
reg     [5:0]        rx_fifo_count_buffer;
reg                  tx_fct_state;
reg     [7:0]        tx_data_buffer;
reg                  tx_data_control_flag_buffer;
wire                 got_fct_sync;
reg     [6:0]        tx_credit_count;
reg                  credit_error_n_char_over_flow;
reg                  credit_error_fct_over_flow;
wire                 tx_ready;
wire                 credit_error;
reg     [5:0]        time_in_buffer;
reg                  first_null_send;
wire                 reset_in;
reg     [5:0]        clk_divide_reg;
reg                  tx_eep_async;
reg                  tx_eop_async;
reg                  tx_byte_async;
reg                  credit_over_flow;
//------------------------------------------------------------------------------
initial 
  begin : process_13
    time_in_buffer = 6'b000000;
  end
//------------------------------------------------------------------------------
assign reset_in         = i_reset | i_space_wire_reset;
assign o_tx_eep_async   = tx_eep_async;
assign o_tx_eop_async   = tx_eop_async;
assign o_tx_byte_async  = tx_byte_async;
//------------------------------------------------------------------------------
space_wire_sync_one_pulse   inst0_transmitDataEnablePulse 
(
  .i_clk                    ( i_tx_clk        ),
  .i_async_clk              ( i_clk           ),
  .i_reset                  ( reset_in        ),
  .i_async_in               ( i_tx_data_en    ),
  .o_sync_out               ( tx_data_en_sync )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse   inst1_tickInPulse 
(
  .i_clk                    ( i_tx_clk        ),
  .i_async_clk              ( i_clk           ),
  .i_reset                  ( reset_in        ),
  .i_async_in               ( i_tick_in       ),
  .o_sync_out               ( tick_in_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse   inst2_gotFCTPulse 
(
  .i_clk                    ( i_tx_clk        ),
  .i_async_clk              ( i_rx_clk        ),
  .i_reset                  ( reset_in        ),
  .i_async_in               ( i_got_fct       ),
  .o_sync_out               ( got_fct_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse   inst3_gotNCharacterPulse 
(
  .i_clk                    ( i_tx_clk        ),
  .i_async_clk              ( i_rx_clk        ),
  .i_reset                  ( reset_in        ),
  .i_async_in               ( i_got_n_char    ),
  .o_sync_out               ( got_n_char_sync )
);
//------------------------------------------------------------------------------
assign o_credit_error           = credit_error;
//------------------------------------------------------------------------------
assign credit_error             = credit_error_n_char_over_flow | 
                                  credit_error_fct_over_flow;
//------------------------------------------------------------------------------
assign o_credit_count_out       = tx_credit_count[5:0];
assign o_outstanding_count_out  = outstanding_count;
assign o_tx_ready               = tx_ready;
//------------------------------------------------------------------------------
assign tx_ready                 = ( send_start                    | 
                                    tx_fct_start                  | 
                                    tx_credit_count == 7'b0000000 ) 
                                    ? 1'b0 : 1'b1;
//------------------------------------------------------------------------------
assign o_space_wire_data_out    = data_out_reg;
assign o_space_wire_strobe_out  = strobe_out_reg;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Statistical information, Transmit One Shot Pulse(EOP,EEP,1Byte).
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_tx_eop_eep_byte
    if ( reset_in )
      begin
        tx_eep_async                <= 1'b0;
        tx_eop_async                <= 1'b0;
        tx_byte_async               <= 1'b0;
      end
    else
      begin
        if ( i_tx_data_en )
          begin
            if ( i_tx_data_control_flag )
              begin
                if ( !i_tx_data[0] )
                  begin
                    // EOP Transmit.
                    tx_eop_async    <= 1'b1;
                  end
                else 
                  begin
                    // EEP Transmit.
                    tx_eep_async    <= 1'b1;
                  end
              end
            else if ( !i_tx_data_control_flag )
              begin
                // 1Byte Transmit.
                tx_byte_async       <= 1'b1;
              end
          end
        else
          begin
            tx_eep_async            <= 1'b0;
            tx_eop_async            <= 1'b0;
            tx_byte_async           <= 1'b0;
         end
      end
   end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.4.2 Transmitter
// When the TICK_IN signal is asserted the transmitter sends out a Time-Code
// as soon as the transmitter has finished sending the current character or 
// control code. The value of the Time-Code is the value of the TIME_IN and 
// CONTROL-FLAGS_IN signals at the point in time when TICK_IN is asserted.
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_tx_time_code_state
    if ( reset_in )
      begin
        tx_time_code_state              <= 1'b0;
        tx_time_code_start              <= 1'b0;
        time_in_buffer                  <= {6{1'b0}};
      end
    else
      begin
        if ( i_send_time_codes )
          begin
            if ( !tx_time_code_state )
              begin
                if ( tick_in_sync )
                  begin
                    tx_time_code_start  <= 1'b1;
                    tx_time_code_state  <= 1'b1;
                    time_in_buffer      <= i_time_in;
                  end
              end
            else
              begin
                if ( tx_time_code_done )
                  begin
                    tx_time_code_start  <= 1'b0;
                    tx_time_code_state  <= 1'b0;
                  end
              end
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.3 Flow control (normative)
// Receives an FCT its transmitter increments the credit count by eight.
// Whenever the transmitter sends an N-Char it decrements the credit count 
// by one.
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_tx_credit_count
    if ( reset_in )
      begin
        tx_credit_count           <= {7{1'b0}};
      end
    else
      begin
        if ( got_fct_sync )
          begin
            if ( decrement_credit )
              begin
                tx_credit_count   <= tx_credit_count + 7;
              end
            else
              begin
                tx_credit_count   <= tx_credit_count + 8;
              end
           end
        else if ( decrement_credit )
          begin
            if ( tx_credit_count != 7'b0000000 )
              begin
                tx_credit_count   <= tx_credit_count - 1;
              end
           end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.5.3.8 CreditError
// If an FCT is received when the credit count is at or close to its maximum
// value (i.e. within eight of the maximum value), the credit count is
// not incremented and a credit error occurs.
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_credit_over_flow
    if ( reset_in )
      begin
        credit_over_flow        <= 1'b0;
      end
    else
      begin
        if ( tx_credit_count > 7'b0111000 )
          begin
            credit_over_flow    <= 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.5.3.8 CreditError
// Synchronized Reset the CreditErrorFCTOverFlow.
//==============================================================================
always @(posedge i_tx_clk)
  begin : s_credit_error_fct_over_flow
    if ( reset_in )
      begin
        credit_error_fct_over_flow    <= 1'b0;
      end
    else
      begin
        credit_error_fct_over_flow    <=  credit_over_flow & 
                                          ~credit_error_fct_over_flow;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Receive Wait time for subtraction OutstandingCount
// after adding i_rx_fifo_count.
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_got_n_char_sync_delay
    if ( reset_in )
      begin
        got_n_char_sync_delay         <= {10{1'b0}};
      end
    else
      begin
        got_n_char_sync_delay[0]      <= got_n_char_sync;
        got_n_char_sync_delay[9:1]    <= got_n_char_sync_delay[8:0];
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Synchronized input signal to i_tx_clk. 
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_rx_fifo_count_buffer
    if ( reset_in )
      begin
        rx_fifo_count_buffer0       <= {6{1'b0}};
        rx_fifo_count_buffer1       <= {6{1'b0}};
        rx_fifo_count_buffer        <= {6{1'b0}};
      end
    else
      begin
        rx_fifo_count_buffer0       <= i_rx_fifo_count;
        rx_fifo_count_buffer1       <= rx_fifo_count_buffer0;
        if ( rx_fifo_count_buffer1 == rx_fifo_count_buffer0 )
          begin
            rx_fifo_count_buffer    <= rx_fifo_count_buffer1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.3 Flow control (normative)
// Each time a link interface receives an FCT its transmitter
// increments the credit count by eight.
// Whenever the transmitter sends an N-Char it decrements the credit
// count by one.
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_tx_fct_state
    if ( reset_in )
      begin
        outstanding_count                   <= 6'b000000;
        tx_fct_state                        <= 1'b0;
        tx_fct_start                        <= 1'b0;
        credit_error_n_char_over_flow       <= 1'b0;
      end
    else
      begin
        if ( !tx_fct_state )
           begin
           if ( outstanding_count + rx_fifo_count_buffer <= 6'b110000 & 
                i_send_fcts )
              begin
                tx_fct_start                <= 1'b1;
                tx_fct_state                <= 1'b1;
              end
           if ( got_n_char_sync_delay[9] )
              begin
                outstanding_count           <= outstanding_count - 1;
              end
           end
        else
          begin
            if ( tx_fct_done )
              begin
                if ( got_n_char_sync_delay[9] )
                  begin
                    outstanding_count       <= outstanding_count + 7;
                  end
                else
                  begin
                    outstanding_count       <= outstanding_count + 8;
                  end
                tx_fct_start                <= 1'b0;
                tx_fct_state                <= 1'b0;
              end
            else
              begin
                if ( got_n_char_sync_delay[9] )
                  begin
                    outstanding_count       <= outstanding_count - 1;
                  end
              end
          end
        //======================================================================
        // ECSS-E-ST-50-12C 8.5.3.8 CreditError
        // Credit error occurs if data is received when the
        // host system is not expecting any more data.                   
        //======================================================================
        if ( got_n_char_sync_delay[9] & outstanding_count == 6'b000000 )
          begin
            credit_error_n_char_over_flow   <= 1'b1;
          end
        else
          begin
            credit_error_n_char_over_flow   <= 1'b0;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Instract to start Transmit and load data to buffer after read the data from 
// TransmitFIFO.
//==============================================================================
always @(posedge i_tx_clk or posedge reset_in)
  begin : s_send_start
    if ( reset_in )
      begin
        send_start                      <= 1'b0;
        tx_data_buffer                  <= {8{1'b0}};
        tx_data_control_flag_buffer     <= 1'b0;
      end
  else
    begin
      if ( tx_data_en_sync )
        begin
           tx_data_buffer               <= i_tx_data;
           tx_data_control_flag_buffer  <= i_tx_data_control_flag;
           send_start                   <= 1'b1;
        end
      else if ( send_done )
        begin
          send_start                    <= 1'b0;
        end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 6.6.5 Initial operating data signalling rate
// After a reset the SpaceWire link transmitter shall initially commence 
// operating at a data signalling rate of (10±1) Mb/s.
//==============================================================================
always @(posedge i_tx_clk or posedge i_reset)
  begin : s_clk_divide_reg
    if ( i_reset )
      begin
        clk_divide_reg        <= C_TX_CLK_DIVIDE_VAL;
      end
    else
      begin
        if ( i_send_n_char )
          begin
            clk_divide_reg    <= i_tx_clk_divide;
          end
        else
          begin
            clk_divide_reg    <= C_TX_CLK_DIVIDE_VAL;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.4.3 Transmit i_clk
// Dividing counter to determine the Transmit signalling rate.
//==============================================================================
always @(posedge i_tx_clk or posedge i_reset)
  begin : s_divide_state
    if ( i_reset )
      begin
        divide_count      <= {6{1'b0}};
        divide_state      <= 1'b0;
      end
    else
      begin
        if ( divide_count >= clk_divide_reg )
          begin
            divide_count   <= {6{1'b0}};
            divide_state   <= 1'b1;
          end
        else
          begin
            divide_count   <= divide_count + 1;
            divide_state   <= 1'b0;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.4.2 Transmitter
// The data is convoert to serial after stored in shift register, Transmit Tx as 
// DS signal. 
// Generate odd parity and Transmit Null data automatically.
//==============================================================================
always @(posedge i_tx_clk or posedge i_reset)
  begin : process_12
    if ( i_reset )
      begin
        tx_parity         <= 1'b0;
        state_tx          <= SM_STOP;
        data_out_reg      <= 1'b0;
        strobe_out_reg    <= 1'b0;
        null_send         <= 1'b0;
        time_code_send    <= 1'b0;
        send_done         <= 1'b0;
        tx_fct_done       <= 1'b0;
        tx_time_code_done <= 1'b0;
        decrement_credit  <= 1'b0;
        first_null_send   <= 1'b0;
        send_count        <= {4{1'b0}};
        send_data         <= {9{1'b0}};
      end
   else
      begin
        if ( divide_state )
          begin
            case ( state_tx )
              SM_STOP:
                begin
                  if ( i_tx_en & i_send_nulls )
                    begin
                      state_tx        <= SM_PARITY;
                    end
                  else
                    begin
                      tx_parity       <= 1'b0;
                      data_out_reg    <= 1'b0;
                      strobe_out_reg  <= 1'b0;
                      null_send       <= 1'b0;
                      first_null_send <= 1'b0;
                    end
                end
              //================================================================
              // Odd Parity Generate.
              //================================================================
              SM_PARITY:
                begin
                  if ( i_tx_en )
                    begin
                      //--------------------------------------------------------
                      if ( null_send )
                        begin
                          // send pending FCT of NULL(ESC+FCT)
                          send_data           <= {6'b000000, 3'b001};
                          send_count          <= 4'h2;
                          if ( data_out_reg == tx_parity )
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= ~strobe_out_reg;
                            end
                          else
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= strobe_out_reg;
                            end
                          null_send           <= 1'b0;
                        end
                      //--------------------------------------------------------
                      else if ( time_code_send )
                        begin
                          // send pending TIME of TCODE(ESC+TIME)
                          send_data     <= {i_control_flags_in, time_in_buffer, 1'b0};
                          send_count    <= 4'h8;
                          if ( data_out_reg == (tx_parity ^ 1'b1) )
                            begin
                              data_out_reg    <= tx_parity ^ 1'b1;
                              strobe_out_reg  <= ~strobe_out_reg;
                            end
                          else
                            begin
                              data_out_reg    <= tx_parity ^ 1'b1;
                              strobe_out_reg  <= strobe_out_reg;
                            end
                          time_code_send      <= 1'b0;
                          tx_time_code_done   <= 1'b1;
                          end
                      //--------------------------------------------------------
                      else if ( tx_time_code_start )
                        begin
                          // send ESC of TCODE.
                          send_data           <= {6'b000000, 3'b111};
                          send_count          <= 4'h2;
                          if (data_out_reg == tx_parity)
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= ~strobe_out_reg;
                            end
                          else
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= strobe_out_reg;
                            end
                          time_code_send      <= 1'b1;
                        end
                      //--------------------------------------------------------
                      else if ( i_send_fcts & tx_fct_start & first_null_send )
                        begin
                          // send FCT.
                          send_data           <= {6'b000000, 3'b001};
                          send_count          <= 4'h2;
                          if (data_out_reg == tx_parity)
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= ~strobe_out_reg;
                            end
                          else
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= strobe_out_reg;
                            end
                          tx_fct_done         <= 1'b1;
                        end
                      //--------------------------------------------------------
                      else if ( i_send_n_char & send_start )
                        begin
                          decrement_credit    <= 1'b1;
                          if (  tx_data_control_flag_buffer & 
                               !tx_data_buffer[0] )
                            begin
                              // send EOP.
                              send_data       <= {1'b0, 5'b00000, 3'b101};
                              send_count      <= 4'h2;
                              if ( data_out_reg == tx_parity )
                                begin
                                  data_out_reg    <= tx_parity;
                                  strobe_out_reg  <= ~strobe_out_reg;
                                end
                              else
                                begin
                                  data_out_reg    <= tx_parity;
                                  strobe_out_reg  <= strobe_out_reg;
                                end
                            end
                          //----------------------------------------------------
                          else if ( tx_data_control_flag_buffer & 
                                    tx_data_buffer[0] )
                            begin
                              // send EEP.
                              send_data   <= {1'b0, 5'b00000, 3'b011};
                              send_count  <= 4'h2;
                              if (data_out_reg == tx_parity)
                                begin
                                  data_out_reg    <= tx_parity;
                                  strobe_out_reg  <= ~strobe_out_reg;
                                end
                              else
                                begin
                                  data_out_reg    <= tx_parity;
                                  strobe_out_reg  <= strobe_out_reg;
                                end
                            end
                          //----------------------------------------------------
                          else
                            begin
                              //  send 8-bit data.
                              send_data   <= {tx_data_buffer, 1'b0};
                              send_count  <= 4'h8;
                              if (data_out_reg == (tx_parity ^ 1'b1))
                                begin
                                  data_out_reg    <= tx_parity ^ 1'b1;
                                  strobe_out_reg  <= ~strobe_out_reg;
                                end
                              else
                                begin
                                  data_out_reg    <= tx_parity ^ 1'b1;
                                  strobe_out_reg  <= strobe_out_reg;
                                end
                            end
                          send_done   <= 1'b1;
                        end
                      //--------------------------------------------------------
                      else if ( i_send_nulls )
                        begin
                          //  send ESC of NULL.
                          send_data   <= {6'b000000, 3'b111};
                          send_count  <= 4'h2;
                          if ( data_out_reg == tx_parity )
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= ~strobe_out_reg;
                            end
                          else
                            begin
                              data_out_reg    <= tx_parity;
                              strobe_out_reg  <= strobe_out_reg;
                            end
                          null_send           <= 1'b1;
                          first_null_send     <= 1'b1;
                        end
                      state_tx                <= SM_CONTROL;
                    end
                  else //!i_tx_en
                    begin
                      data_out_reg            <= 1'b0;
                      state_tx                <= SM_STOP;
                    end
                end
              //==============================================================================
              // Transmit Data Control Flag
              // Data Character = "0" Control Caracter = "1".
              //==============================================================================
              SM_CONTROL:
                begin
                  if ( i_tx_en )
                    begin
                      send_done           <= 1'b0;
                      decrement_credit    <= 1'b0;
                      tx_fct_done         <= 1'b0;
                      tx_time_code_done   <= 1'b0;
                      send_count          <= send_count - 1;
                      if ( data_out_reg == send_data[0] )
                        begin
                          data_out_reg    <= send_data[0];
                          strobe_out_reg  <= ~strobe_out_reg;
                        end
                      else
                        begin
                          data_out_reg    <= send_data[0];
                          strobe_out_reg  <= strobe_out_reg;
                        end
                      send_data           <= {1'b0, send_data[8:1]};
                      tx_parity           <= 1'b0;
                      state_tx            <= SM_DATA;
                    end
                  else
                    begin
                      data_out_reg        <= 1'b0;
                      state_tx            <= SM_STOP;
                    end
                end
              //================================================================
              // Transmit Data Character or Control Caracter.
              //================================================================
              SM_DATA:
                begin
                  if ( i_tx_en )
                    begin
                      if ( data_out_reg == send_data[0] )
                        begin
                          data_out_reg    <= send_data[0];
                          strobe_out_reg  <= ~strobe_out_reg;
                        end
                      else
                        begin
                          data_out_reg    <= send_data[0];
                          strobe_out_reg  <= strobe_out_reg;
                        end
                      tx_parity           <= tx_parity ^ send_data[0];
                      send_data           <= {1'b0, send_data[8:1]};
                      if ( send_count == 4'b0000 )
                        begin
                          state_tx        <= SM_PARITY;
                        end
                      else
                        begin
                          send_count      <= send_count - 1;
                        end
                    end
                  else
                    begin
                      data_out_reg        <= 1'b0;
                      state_tx            <= SM_STOP;
                    end
                end
              //================================================================
              default:
                ;
            endcase
          end
        else
          begin
            tx_fct_done         <= 1'b0;
            send_done           <= 1'b0;
            decrement_credit    <= 1'b0;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_tx

