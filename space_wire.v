//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire 
(
  input    wire                 i_clk,
  input    wire                 i_tx_clk,
  input    wire                 i_rx_clk,
  input    wire                 i_reset_n,
  //
  input    wire                 i_tx_fifo_wren,
  input    wire    [8:0]        i_tx_fifo_data_in,
  output   wire                 o_tx_fifo_full,
  output   wire    [5:0]        o_tx_fifo_rdusdw,
  //
  input    wire                 i_rx_fifo_rden,
  output   wire    [8:0]        o_rx_fifo_q,
  output   wire                 o_rx_fifo_full,
  output   wire                 o_rx_fifo_empty,
  output   wire    [5:0]        o_rx_fifo_data_count,
  //
  input    wire                 i_tick_in,
  input    wire    [5:0]        i_time_in,
  input    wire    [1:0]        i_control_flags_in,  // reserved for future use
  output   wire                 o_tick_out,
  output   wire    [5:0]        o_time_out,
  output   wire    [1:0]        o_control_flags_out, // reserved for future use
  input    wire                 i_link_start,
  input    wire                 i_link_disable,
  input    wire                 i_auto_start,
  output   wire    [15:0]       o_link_status,
  output   wire    [7:0]        o_error_status,
  input    wire    [5:0]        i_tx_clk_divide_val,
  output   wire    [5:0]        o_credit_count,
  output   wire    [5:0]        o_outstanding_count,
  output   wire                 o_tx_activity,
  output   wire                 o_rx_activity,
  output   wire                 o_space_wire_data_out,
  output   wire                 o_space_wire_strobe_out,
  input    wire                 i_space_wire_data_in,
  input    wire                 i_space_wire_strobe_in,
  input    wire                 i_stat_info_clear,
  output   wire    [7:0]        o_stat_info_0,
  output   wire    [7:0]        o_stat_info_1,
  output   wire    [7:0]        o_stat_info_2,
  output   wire    [7:0]        o_stat_info_3,
  output   wire    [7:0]        o_stat_info_4,
  output   wire    [7:0]        o_stat_info_5,
  output   wire    [7:0]        o_stat_info_6,
  output   wire    [7:0]        o_stat_info_7
);
//------------------------------------------------------------------------------
// Declare constants.
//------------------------------------------------------------------------------
// i_tx_clk period * C_DISCONNECT_CNT_VAL = 850ns.
localparam  [7:0]    C_DISCONNECT_CNT_VAL     = 141;
// i_clk period (50MHz) * C_TIMER_6_4_US_VAL = 6.4us.
localparam  [9:0]    C_TIMER_6_4_US_VAL       = 320;
// i_clk period (50MHz) * C_TIMER_12_8_US_VAL = 12.8us.
localparam  [10:0]   C_TIMER_12_8_US_VAL      = 640;
// i_tx_clk frequency / (C_TX_CLK_DIVIDE_VAL + 1) = 10MHz.
localparam  [5:0]    C_TX_CLK_DIVIDE_VAL      = 6'b001001;
//------------------------------------------------------------------------------
wire    tx_busy; 
wire    tx_busy_sync; 
//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
// TYPE state_tx_wr:
localparam STXWR_IDLE    = 0;
localparam STXWR_WRITE0  = 1;
localparam STXWR_WRITE1  = 2;
localparam STXWR_RESET0  = 3;
localparam STXWR_RESET1  = 4;
localparam STXWR_RESET2  = 5;
//------------------------------------------------------------------------------
reg     [2:0]        state_tx_wr; 
//------------------------------------------------------------------------------
// transmitter
reg                  tx_data_en; 
wire    [7:0]        tx_data; 
wire                 tx_data_control_flag; 
wire                 tx_ready; 
// receiver
wire                 rx_fifo_wren1; 
wire    [7:0]        rx_data; 
wire                 rx_data_control_flag; 
wire    [5:0]        rx_fifo_rdusdw; 
reg                  tx_fifo_rden; 
wire                 tx_fifo_empty; 
wire    [8:0]        tx_fifo_q; 
wire    [8:0]        rx_fifo_data; 
wire                 rx_fifo_wren2; 
wire                 space_wire_reset_n; 
reg                  rx_fifo_reset; 
reg                  tx_pckt_middle; 
reg                  rx_pckt_middle; 
reg                  rx_pckt_middle_sync; 
wire                 fifo_available; 
reg                  rx_fifo_wr_EEP; 
//------------------------------------------------------------------------------
assign tx_data               = tx_fifo_q[7:0];
assign tx_data_control_flag  = tx_fifo_q[8];
assign o_tx_activity         = tx_fifo_rden;
assign o_rx_activity         = rx_fifo_wren1;
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
// FIFO. TX
//------------------------------------------------------------------------------
space_wire_fifo_9x64                   inst0_space_wire_fifo_9x64_tx
(
  .i_wr_clk                            ( i_clk                 ),
  .i_wren                              ( i_tx_fifo_wren        ),
  .i_data                              ( i_tx_fifo_data_in     ),
  //---
  .i_rd_clk                            ( i_clk                 ),
  .i_rden                              ( tx_fifo_rden          ),
  .o_q                                 ( tx_fifo_q             ),
  //---
  .o_wrusdw                            (                       ),
  .o_rdusdw                            ( o_tx_fifo_rdusdw      ),
  .o_empty                             ( tx_fifo_empty         ),
  .o_full                              ( o_tx_fifo_full        ),
  //---
  .i_reset_n                           ( i_reset_n             )
);
//------------------------------------------------------------------------------
// FIFO. RX
//------------------------------------------------------------------------------
space_wire_fifo_9x64                   inst1_space_wire_fifo_9x64_rx
(
  .i_wr_clk                            ( i_rx_clk             ),
  .i_wren                              ( rx_fifo_wren2        ),
  .i_data                              ( rx_fifo_data         ),
  //---
  .i_rd_clk                            ( i_clk                ),
  .i_rden                              ( i_rx_fifo_rden       ),
  .o_q                                 ( o_rx_fifo_q          ),
  //---
  .o_wrusdw                            (                      ),
  .o_rdusdw                            ( rx_fifo_rdusdw       ),
  .o_empty                             ( o_rx_fifo_empty      ),
  .o_full                              ( o_rx_fifo_full       ),
  //---
  .i_reset_n                           ( i_reset_n            )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse              inst2_transmitReadyPulse
(
  .i_clk                               ( i_clk                ),
  .i_async_clk                         ( i_tx_clk             ),
  .i_reset_n                           ( i_reset_n            ),
  .i_async_in                          ( tx_busy              ),
  .o_sync_out                          ( tx_busy_sync         )
);
//------------------------------------------------------------------------------
space_wire_link_interface
#(
  .C_DISCONNECT_CNT_VAL                ( C_DISCONNECT_CNT_VAL ),
  .C_TIMER_6_4_US_VAL                  ( C_TIMER_6_4_US_VAL   ),
  .C_TIMER_12_8_US_VAL                 ( C_TIMER_12_8_US_VAL  ),
  .C_TX_CLK_DIVIDE_VAL                 ( C_TX_CLK_DIVIDE_VAL  )
)
inst3_space_wire_link_interface
(
  .i_clk                               ( i_clk                       ),
  .i_reset_n                           ( i_reset_n                   ),
  // state machine.
  .i_tx_clk                            ( i_tx_clk                    ),
  .i_link_start                        ( i_link_start                ),
  .i_link_disable                      ( i_link_disable              ),
  .i_auto_start                        ( i_auto_start                ),
  .o_link_status                       ( o_link_status               ),
  .o_error_status                      ( o_error_status              ),
  .o_space_wire_reset_n_out            ( space_wire_reset_n          ),
  .i_fifo_available                    ( fifo_available              ),
  // transmitter.
  .i_tick_in                           ( i_tick_in                   ),
  .i_time_in                           ( i_time_in                   ),
  .i_control_flags_in                  ( i_control_flags_in          ),
  .i_tx_data_en                        ( tx_data_en                  ),
  .i_tx_data                           ( tx_data                     ),
  .i_tx_data_control_flag              ( tx_data_control_flag        ),
  .o_tx_ready                          ( tx_ready                    ),
  .i_tx_clk_divide_val                 ( i_tx_clk_divide_val         ),
  .o_credit_count                      ( o_credit_count              ),
  .o_outstnding_count                  ( o_outstanding_count         ),
  // receiver.
  .i_rx_clk                            ( i_rx_clk                    ),
  .o_tick_out                          ( o_tick_out                  ),
  .o_time_out                          ( o_time_out                  ),
  .o_control_flags_out                 ( o_control_flags_out         ),
  .o_rx_fifo_wren1                     ( rx_fifo_wren1               ),
  .o_rx_data                           ( rx_data                     ),
  .o_rx_data_control_flag              ( rx_data_control_flag        ),
  .i_rx_fifo_rdusdw                    ( rx_fifo_rdusdw              ),
  // serial i/o.
  .o_space_wire_data_out               ( o_space_wire_data_out       ),
  .o_space_wire_strobe_out             ( o_space_wire_strobe_out     ),
  .i_space_wire_data_in                ( i_space_wire_data_in        ),
  .i_space_wire_strobe_in              ( i_space_wire_strobe_in      ),
  .i_stat_info_clear                   ( i_stat_info_clear           ),
  .o_stat_info_0                       ( o_stat_info_0               ),
  .o_stat_info_1                       ( o_stat_info_1               ),
  .o_stat_info_2                       ( o_stat_info_2               ),
  .o_stat_info_3                       ( o_stat_info_3               ),
  .o_stat_info_4                       ( o_stat_info_4               ),
  .o_stat_info_5                       ( o_stat_info_5               ),
  .o_stat_info_6                       ( o_stat_info_6               ),
  .o_stat_info_7                       ( o_stat_info_7               )
);
//------------------------------------------------------------------------------
assign rx_fifo_data              = ( rx_fifo_wr_EEP ) 
                                   ? 9'b100000001 : 
                                   {rx_data_control_flag, rx_data};
//------------------------------------------------------------------------------
assign rx_fifo_wren2             = rx_fifo_wren1 | rx_fifo_wr_EEP;
assign o_rx_fifo_data_count      = rx_fifo_rdusdw;
//------------------------------------------------------------------------------
assign fifo_available            = ( tx_pckt_middle | rx_pckt_middle_sync ) 
                                   ? 1'b0 : 1'b1;
//------------------------------------------------------------------------------
assign tx_busy                   = ~tx_ready;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 11.4  Link error recovery.
// If previous character was NOT EOP, then add EEP (error end of
// packet) to the receiver buffer, when detect Error(SpaceWireReset) while 
// receiving the Receive packet.
//==============================================================================
// rx_pckt_middle - illuminates the body of the package (with exception of EOP)
//          rx_pckt_middle       EOP
// ___[d][d][d][d][d][d][d][d][d][d]___
//------------------------------------------------------------------------------
reg        space_wire_reset_n_z0;
reg        space_wire_reset_n_z1;
//------------------------------------------------------------------------------
always @(posedge i_rx_clk or negedge i_reset_n)
  begin : s_link_error_recovery
    if ( !i_reset_n )
      begin
        rx_pckt_middle              <= 1'b0;
        rx_fifo_wr_EEP              <= 1'b0;
        rx_fifo_reset               <= 1'b0;
      end
    else
      begin
        // exclusion of metastability and transfer to another clock domain
        space_wire_reset_n_z0   <= space_wire_reset_n;
        space_wire_reset_n_z1   <= space_wire_reset_n_z0;
        if ( !space_wire_reset_n_z1 )
          begin
           rx_fifo_reset            <= 1'b1;
          end
        else
          begin
           rx_fifo_reset            <= 1'b0;
          end
        if ( rx_fifo_reset )
          begin
            if ( rx_pckt_middle )
              begin
                rx_pckt_middle      <= 1'b0;
                rx_fifo_wr_EEP      <= 1'b1;
              end
            else
              begin
                rx_fifo_wr_EEP      <= 1'b0;
              end
          end
        else if ( rx_fifo_wren1 )
          begin
            if ( rx_fifo_data[8] )
              begin
                rx_pckt_middle      <= 1'b0;
              end
            else
              begin
                rx_pckt_middle      <= 1'b1;
              end
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 11.4 Link error recovery.
// Delete data in the  transmitter buffer until the next EOP,
// when detect  Error (SpaceWireReset) while sending
// the Receive packet.
//==============================================================================
always @(posedge i_clk or negedge i_reset_n)
  begin : s_state_tx_wr
    if ( !i_reset_n )
      begin
        tx_data_en                         <= 1'b0;
        tx_fifo_rden                       <= 1'b0;
        tx_pckt_middle                     <= 1'b0;
        state_tx_wr                        <= STXWR_IDLE;
      end
    else
      begin
        case (state_tx_wr)
          // 0
          STXWR_IDLE:
            begin
              if ( !space_wire_reset_n & tx_pckt_middle )
                begin
                  state_tx_wr              <= STXWR_RESET0;
                end
              else
                begin
                  if ( !tx_fifo_empty & tx_ready )
                    begin
                      tx_fifo_rden         <= 1'b1;
                      state_tx_wr          <= STXWR_WRITE0;
                    end
                end
            end
          // 1
          STXWR_WRITE0:
            begin
              tx_data_en                   <= 1'b1; 
              tx_fifo_rden                 <= 1'b0;
              state_tx_wr                  <= STXWR_WRITE1;
            end
          // 2
          STXWR_WRITE1:
            begin
              tx_data_en                   <= 1'b0;
              if ( !space_wire_reset_n )
                begin
                  if ( tx_fifo_q[8] )
                    begin
                      tx_pckt_middle       <= 1'b0;
                      state_tx_wr          <= STXWR_IDLE;
                    end
                  else
                    begin
                      tx_pckt_middle       <= 1'b1;
                      state_tx_wr          <= STXWR_RESET0;
                    end
                end
              else
                begin
                  if ( tx_busy_sync )
                    begin
                      if ( tx_fifo_q[8] )
                        begin
                          tx_pckt_middle   <= 1'b0;
                        end
                      else
                        begin
                          tx_pckt_middle   <= 1'b1;
                        end
                    state_tx_wr            <= STXWR_IDLE;
                    end
                end
            end
          // 3
          STXWR_RESET0:
            begin
              if ( !tx_fifo_empty )
                begin
                  tx_fifo_rden             <= 1'b1;
                  state_tx_wr              <= STXWR_RESET1;
                end
            end
          // 4
          STXWR_RESET1:
            begin
              tx_fifo_rden                 <= 1'b0;
              state_tx_wr                  <= STXWR_RESET2;
            end
          // 5
          STXWR_RESET2:
            begin
              if ( tx_fifo_q[8] )
                begin
                  tx_pckt_middle           <= 1'b0;
                  state_tx_wr              <= STXWR_IDLE;
                end
              else
                begin
                  tx_pckt_middle           <= 1'b1;
                  state_tx_wr              <= STXWR_RESET0;
                end
              end
          default:
            begin
              state_tx_wr                  <= STXWR_IDLE;
            end
      endcase
      end
   end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// synchronize the Receive data receiving signal and the SystemClock.
//==============================================================================
always @(posedge i_clk or negedge i_reset_n)
  begin : s_rx_pckt_middle
    if ( !i_reset_n )
      begin
        rx_pckt_middle_sync      <= 1'b0;
      end
    else
      begin
        if ( rx_pckt_middle )
          begin
            rx_pckt_middle_sync  <= 1'b1;
          end
        else
          begin
            rx_pckt_middle_sync  <= 1'b0;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire
