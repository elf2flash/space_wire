//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_time_code_control
(
  input    wire                 i_clk,
  input    wire                 i_reset_n,
  input    wire                 i_rx_clk,
  input    wire                 i_got_time_code,
  input    wire    [7:0]        i_rx_time_code,
  output   wire    [5:0]        o_time_out,
  output   wire    [1:0]        o_control_flags_out, // reserved for future use
  output   wire                 o_tick_out
);
//------------------------------------------------------------------------------
reg     [7:0]        rx_time_code_reg; 
reg     [1:0]        control_flags; 
reg     [5:0]        rx_time_code; 
reg     [5:0]        rx_time_code_plus1; 
reg                  tick_out; 
wire                 got_time_code_sync; 
//------------------------------------------------------------------------------
assign o_time_out           = rx_time_code; 
assign o_control_flags_out  = control_flags; 
assign o_tick_out           = tick_out; 
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.12 System time distribution (normative)
// ECSS-E-ST-50-12C 7.3 Control characters and control codes
// The new time should be one more than the time-counter's previous
// time-value.
//==============================================================================
always @(posedge i_clk or negedge i_reset_n)
  begin : s_tick_out
    if ( !i_reset_n )
      begin
        rx_time_code                 <= {6{1'b0}};
        rx_time_code_plus1           <= 6'b000001;
        tick_out                     <= 1'b0;
        control_flags                <= 2'b00;
        rx_time_code_reg             <= {8{1'b0}};
      end
    else
      begin
        if ( got_time_code_sync )
          begin
            control_flags            <= rx_time_code_reg[7:6];
            rx_time_code             <= rx_time_code_reg[5:0];
            rx_time_code_plus1       <= rx_time_code_reg[5:0] + 1;
            if ( rx_time_code_plus1 == rx_time_code_reg[5:0] )
              begin
                tick_out             <= 1'b1;
              end
          end
        else
          begin
            tick_out                 <= 1'b0;
          end
        rx_time_code_reg             <= i_rx_time_code;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
space_wire_sync_one_pulse  inst0_time_code_pulse 
(
  .i_clk                   ( i_clk              ),
  .i_async_clk             ( i_rx_clk           ),
  .i_reset_n               ( i_reset_n          ),
  .i_async_in              ( i_got_time_code    ),
  .o_sync_out              ( got_time_code_sync )
);
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_time_code_control

