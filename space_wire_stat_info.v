//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_stat_info
(
  input    wire                 i_clk,
  input    wire                 i_reset,
  input    wire                 i_stat_clear,
  input    wire                 i_tx_clk,
  input    wire                 i_rx_clk,
  input    wire                 i_rx_eep_async,
  input    wire                 i_rx_eop_async,
  input    wire                 i_rx_byte_async,
  input    wire                 i_tx_eep_async,
  input    wire                 i_tx_eop_async,
  input    wire                 i_tx_byte_async,
  input    wire                 i_link_up_transition,
  input    wire                 i_link_down_transition,
  input    wire                 i_link_up_en,
  input    wire                 i_null_sync,
  input    wire                 i_fct_sync,
  output   wire    [7:0]        o_stat_info_0,
  output   wire    [7:0]        o_stat_info_1,
  output   wire    [7:0]        o_stat_info_2,
  output   wire    [7:0]        o_stat_info_3,
  output   wire    [7:0]        o_stat_info_4,
  output   wire    [7:0]        o_stat_info_5,
  output   wire    [7:0]        o_stat_info_6,
  output   wire    [7:0]        o_stat_info_7,
  output   wire    [6:0]        o_char_mon
);
//------------------------------------------------------------------------------
reg     [31:0]       tx_eop_count; 
reg     [31:0]       rx_eop_count; 
reg     [31:0]       tx_eep_count; 
reg     [31:0]       rx_eep_count; 
reg     [31:0]       tx_byte_count; 
reg     [31:0]       rx_byte_count; 
reg     [31:0]       link_up_count; 
reg     [31:0]       link_down_count; 
//------------------------------------------------------------------------------
reg     [6:0]        char_mon; 
//------------------------------------------------------------------------------
wire                 rx_eep_sync; 
wire                 rx_eop_sync; 
wire                 rx_byte_sync; 
wire                 tx_eep_sync; 
wire                 tx_eop_sync; 
wire                 tx_byte_sync; 
//------------------------------------------------------------------------------
assign o_char_mon    = char_mon; 
//------------------------------------------------------------------------------
assign o_stat_info_0 = tx_eop_count; 
assign o_stat_info_1 = rx_eop_count; 
assign o_stat_info_2 = tx_eep_count; 
assign o_stat_info_3 = rx_eep_count; 
assign o_stat_info_4 = tx_byte_count; 
assign o_stat_info_5 = rx_byte_count; 
assign o_stat_info_6 = link_up_count; 
assign o_stat_info_7 = link_down_count; 
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
//  One Shot Status Information.
//==============================================================================
always @(i_clk or i_reset)
  begin : s_char_mon
    if ( i_reset )
      begin
        char_mon    <= {7{1'b0}};
      end
    else
      begin
        char_mon    <= { rx_eep_sync, rx_eop_sync, i_fct_sync, i_null_sync, 
                         rx_byte_sync, tx_byte_sync, i_link_up_en };
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
//  Statistical Information Counter.
//  Transmit and Receive EOP, EEP, 1Byte, SpaceWireLinkUP and SpaceWireLinkDown 
//  Increment Counter.
//  Status Information
//  Receive EOP, EEP, FCT, Null and 1Byte One Shot Pulse
//  Transmit 1Byte One Shot Pulse.
//==============================================================================
//---
//---
//---
//==============================================================================
//  Transmit EOP, EEP and 1Byte Increment Counter.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge i_stat_clear)
  begin : s_tx_eep_eop_byte_count
    if ( i_reset | i_stat_clear )
      begin
        tx_eop_count       <= {32{1'b0}};
        tx_eep_count       <= {32{1'b0}};
        tx_byte_count      <= {32{1'b0}};
      end
    else
      begin
        if ( tx_eep_sync )
          begin
            tx_eep_count   <= tx_eep_count + 1'b1;
          end
        if ( tx_eop_sync )
          begin
            tx_eop_count   <= tx_eop_count + 1'b1;
          end
        if ( tx_byte_sync )
          begin
            tx_byte_count  <= tx_byte_count + 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
//  receive EOP,EEP,1Byte Increment Counter.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge i_stat_clear)
  begin : s_rx_eep_eop_byte_count
    if ( i_reset | i_stat_clear )
      begin
        rx_eop_count       <= {32{1'b0}};
        rx_eep_count       <= {32{1'b0}};
        rx_byte_count      <= {32{1'b0}};
      end
    else
      begin
        if ( rx_eep_sync )
          begin
            rx_eep_count   <= rx_eep_count + 1'b1;
          end
        if ( rx_eop_sync )
          begin
            rx_eop_count   <= rx_eop_count + 1'b1;
          end
        if ( rx_byte_sync )
          begin
            rx_byte_count  <= rx_byte_count + 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
//  SpaceWireLinkUP and SpaceWireLinkDown Increment Counter.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge i_stat_clear)
  begin : s_link_count
    if ( i_reset | i_stat_clear )
      begin
        link_up_count        <= {32{1'b0}};
        link_down_count      <= {32{1'b0}};
      end
    else
      begin
        if ( i_link_up_transition )
          begin
            link_up_count    <= link_up_count + 1'b1;
          end
        if ( i_link_down_transition )
          begin
            link_down_count  <= link_down_count + 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst0_receiveEEPPulse
(
  .i_clk                   ( i_clk          ),
  .i_async_clk             ( i_rx_clk       ),
  .i_reset                 ( i_reset        ),
  .i_async_in              ( i_rx_eep_async ),
  .o_sync_out              ( rx_eep_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst1_receiveEOPPulse
(
  .i_clk                   ( i_clk          ),
  .i_async_clk             ( i_rx_clk       ),
  .i_reset                 ( i_reset        ),
  .i_async_in              ( i_rx_eop_async ),
  .o_sync_out              ( rx_eop_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst2_receiveBytePulse
(
  .i_clk                   ( i_clk           ),
  .i_async_clk             ( i_rx_clk        ),
  .i_reset                 ( i_reset         ),
  .i_async_in              ( i_rx_byte_async ),
  .o_sync_out              ( rx_byte_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst3_transmitEEPPulse
(
  .i_clk                   ( i_clk          ),
  .i_async_clk             ( i_tx_clk       ),
  .i_reset                 ( i_reset        ),
  .i_async_in              ( i_tx_eep_async ),
  .o_sync_out              ( tx_eep_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst4_transmitEOPPulse
(
  .i_clk                   ( i_clk          ),
  .i_async_clk             ( i_tx_clk       ),
  .i_reset                 ( i_reset        ),
  .i_async_in              ( i_tx_eop_async ),
  .o_sync_out              ( tx_eop_sync    )
);
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst5_transmitBytePulse
(
  .i_clk                   ( i_clk           ),
  .i_async_clk             ( i_tx_clk        ),
  .i_reset                 ( i_reset         ),
  .i_async_in              ( i_tx_byte_async ),
  .o_sync_out              ( tx_byte_sync    )
);
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_stat_info

