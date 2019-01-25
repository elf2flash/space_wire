//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_timer 
#(
  parameter    C_TIMER_6_4_US_VAL    = 640,
  parameter    C_TIMER_12_8_US_VAL   = 1280
)
(
  input    wire                 i_clk,
  input    wire                 i_reset,
  input    wire                 i_timer_6p4_us_reset,
  input    wire                 i_timer_12p8_us_start,
  output   wire                 o_after_6p4_us,
  output   wire                 o_after_12p8_us
);
//------------------------------------------------------------------------------
reg                  timer_state_12p8_us;
reg     [9:0]        timer_count_6p4_us;
reg     [10:0]       timer_count_12p8_us;
reg                  after_6p4_us; 
reg                  after_12p8_us; 
//------------------------------------------------------------------------------
assign o_after_6p4_us   = after_6p4_us;
assign o_after_12p8_us  = after_12p8_us;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C  8.4.7 Timer.
// The timer provides the After 6.4 us and After 12.8 us timeouts used 
// in link initialization.
//==============================================================================
//---
//---
//---
//==============================================================================
// After 6.4us.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge i_timer_6p4_us_reset)
  begin : s_control_timer64
    if ( i_reset | i_timer_6p4_us_reset )
      begin
        timer_count_6p4_us       <= {10{1'b0}};
        after_6p4_us             <= 1'b0;
      end
    else
      begin
        if ( timer_count_6p4_us < C_TIMER_6_4_US_VAL )
          begin
           timer_count_6p4_us    <= timer_count_6p4_us + 1;
           after_6p4_us          <= 1'b0;
          end
        else
          begin
            timer_count_6p4_us    <= {10{1'b0}};
            after_6p4_us          <= 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// After 12.8us.
//==============================================================================
always @(posedge i_clk or posedge i_reset or posedge i_timer_12p8_us_start or posedge i_timer_6p4_us_reset)
  begin : s_control_timer128
    if ( i_reset | i_timer_6p4_us_reset )
      begin
        timer_state_12p8_us          <= 1'b0;
        timer_count_12p8_us          <= {11{1'b0}};
        after_12p8_us                <= 1'b0;
      end
    else
      begin
        if ( !timer_state_12p8_us )
          begin
            after_12p8_us            <= 1'b0;
            if ( i_timer_12p8_us_start )
              begin
                timer_state_12p8_us  <= 1'b1;
              end
          end
        else
          begin
            if ( timer_count_12p8_us < C_TIMER_12_8_US_VAL )
              begin
                timer_count_12p8_us  <= timer_count_12p8_us + 1;
                after_12p8_us        <= 1'b0;
              end
            else
              begin
                timer_count_12p8_us  <= {11{1'b0}};
                timer_state_12p8_us  <= 1'b0;
                after_12p8_us        <= 1'b1;
              end
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_timer

