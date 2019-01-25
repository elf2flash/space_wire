//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_sync_one_pulse
(
  input    wire        i_clk,
  input    wire        i_async_clk,
  input    wire        i_reset,
  input    wire        i_async_in,
  output   wire        o_sync_out
);
//------------------------------------------------------------------------------
reg     latched_async; 
reg     sync_reg; 
reg     sync_clear; 
reg     sync_out; 
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
//  Synchronize the asynchronous One Shot Pulse to Clock.
//------------------------------------------------------------------------------
assign o_sync_out = sync_out;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// latch the rising edge of the input signal.
//==============================================================================
always @(posedge i_async_in or posedge i_reset or posedge sync_clear)
  begin : s_latched_async
    if ( i_reset | sync_clear )
      begin
        latched_async  <= 1'b0;
      end
    else
      begin
        latched_async  <= 1'b1;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Synchronize a latch signal to Clock.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge sync_clear)
  begin : s_sync_reg
    if ( i_reset | sync_clear )
      begin
        sync_reg       <= 1'b0;
      end
    else
      begin
        if ( latched_async )
          begin
            sync_reg   <= 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Output Clock synchronized One_Shot_Pulse and clear signal.
//==============================================================================
always @(posedge i_clk or posedge i_reset)
  begin : s_sync_clear_and_out
    if ( i_reset )
      begin
        sync_out         <= 1'b0;
        sync_clear       <= 1'b0;
      end
    else
      begin
        if ( sync_reg & !sync_clear )
          begin
            sync_out     <= 1'b1;
            sync_clear   <= 1'b1;
          end
        else if ( sync_reg )
          begin
            sync_out     <= 1'b0;
            sync_clear   <= 1'b0;
          end
        else
          begin
            sync_out     <= 1'b0;
            sync_clear   <= 1'b0;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_sync_one_pulse

