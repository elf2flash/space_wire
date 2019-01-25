//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_link_interface 
#(
  parameter [7:0]   C_DISCONNECT_CNT_VAL   = 141,
  parameter [9:0]   C_TIMER_6_4_US_VAL     = 320,
  parameter [10:0]  C_TIMER_12_8_US_VAL    = 640,
  parameter [5:0]   C_TX_CLK_DIVIDE_VAL    = 6'b001001
)
(
  input    wire                 i_clk,
  input    wire                 i_reset,
  input    wire                 i_tx_clk,
  input    wire                 i_link_start,
  input    wire                 i_link_disable,
  input    wire                 i_auto_start,
  output   wire    [15:0]       o_link_status,
  output   wire    [7:0]        o_error_status,
  output   wire                 o_space_wire_reset_out,
  input    wire                 i_fifo_available,
  input    wire                 i_tick_in,
  input    wire    [5:0]        i_time_in,
  input    wire    [1:0]        i_control_flags_in,
  input    wire                 i_tx_data_en,
  input    wire    [7:0]        i_tx_data,
  input    wire                 i_tx_data_control_flag,
  output   wire                 o_tx_ready,
  input    wire    [5:0]        i_tx_clk_divide_val,
  output   wire    [5:0]        o_credit_count,
  output   wire    [5:0]        o_outstnding_count,
  input    wire                 i_rx_clk,
  output   wire                 o_tick_out,
  output   wire    [5:0]        o_time_out,
  output   wire    [1:0]        o_control_flags_out,
  output   wire                 o_rx_fifo_wr_en1,
  output   wire    [7:0]        o_rx_data,
  output   wire                 o_rx_data_control_flag,
  input    wire    [5:0]        i_rx_fifo_count,
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
wire             got_fct;
wire             got_time_code;
wire             got_n_char;
wire             got_null;
wire             got_bit;
wire             credit_error;
wire             parity_error;
wire             escape_error;
wire             disconnect_error;
wire             rx_error;
wire             rx_en;
wire             send_n_char;
wire             send_time_code;
wire             after_12p8_us;
wire             after_6p4_us;
wire             tx_en;
wire             send_nulls;
wire             send_fcts;
wire             space_wire_reset_out_signal;
wire             char_sequence_error;
wire             timer_6p4_us_reset;
wire             timer_12p8_us_start;
wire             rx_fifo_wr_en0;
wire             rx_fifo_wr_en1;
wire             rx_off;
wire    [7:0]    rx_time_code_out;
wire             link_up_tx_sync;
wire             link_down_tx_sync;
wire             link_up_en;
wire             null_sync;
wire             fct_sync;
wire             rx_eep_async;
wire             rx_eop_async;
wire             rx_byte_async;
wire             tx_eep_async;
wire             tx_eop_async;
wire             tx_byte_async;
wire    [6:0]    char_mon;
wire    [8:0]    rx_data_out;
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
assign o_rx_data                 = rx_data_out[7:0];
assign o_rx_data_control_flag    = rx_data_out[8];
//------------------------------------------------------------------------------
space_wire_rx 
#(
  .C_DISCONNECT_CNT_VAL      ( C_DISCONNECT_CNT_VAL )
)
inst0_space_wire_rx 
(
  .i_space_wire_data_in      ( i_space_wire_data_in                ),
  .i_space_wire_strobe_in    ( i_space_wire_strobe_in              ),
  .o_rx_data_out             ( rx_data_out                         ),
  .o_rx_data_valid_out       ( rx_byte_async                       ),
  .o_rx_time_code_out        ( rx_time_code_out                    ),
  .o_rx_time_code_valid_out  ( got_time_code                       ),
  .o_rx_fct_out              ( got_fct                             ),
  .o_rx_n_char_out           ( got_n_char                          ),
  .o_rx_null_out             ( got_null                            ),
  .o_rx_eep_out              ( rx_eep_async                        ),
  .o_rx_eop_out              ( rx_eop_async                        ),
  .o_rx_off_out              ( rx_off                              ),
  .o_rx_error_out            ( rx_error                            ),
  .o_parity_error_out        ( parity_error                        ),
  .o_escape_error_out        ( escape_error                        ),
  .o_disconnect_error_out    ( disconnect_error                    ),
  .i_space_wire_reset        ( space_wire_reset_out_signal         ),
  .o_rx_fifo_wr_en           ( rx_fifo_wr_en0                      ),
  .i_rx_en                   ( rx_en                               ),
  .i_rx_clk                  ( i_rx_clk                            )
);
//------------------------------------------------------------------------------
space_wire_tx 
#(
  .C_TX_CLK_DIVIDE_VAL          ( C_TX_CLK_DIVIDE_VAL )
)
inst1_space_wire_tx 
(
  .i_tx_clk                     ( i_tx_clk                     ),
  .i_clk                        ( i_clk                        ),
  .i_rx_clk                     ( i_rx_clk                     ),
  .i_reset                      ( i_reset                      ),
  .o_space_wire_data_out        ( o_space_wire_data_out        ),
  .o_space_wire_strobe_out      ( o_space_wire_strobe_out      ),
  .i_tick_in                    ( i_tick_in                    ),
  .i_time_in                    ( i_time_in                    ),
  .i_control_flags_in           ( i_control_flags_in           ),
  .i_tx_data_en                 ( i_tx_data_en                 ),
  .i_tx_data                    ( i_tx_data                    ),
  .i_tx_data_control_flag       ( i_tx_data_control_flag       ),
  .o_tx_ready                   ( o_tx_ready                   ),
  .i_tx_en                      ( tx_en                        ),
  .i_send_nulls                 ( send_nulls                   ),
  .i_send_fcts                  ( send_fcts                    ),
  .i_send_n_char                ( send_n_char                  ),
  .i_send_time_codes            ( send_time_code               ),
  .i_got_fct                    ( got_fct                      ),
  .i_got_n_char                 ( got_n_char                   ),
  .i_rx_fifo_count              ( i_rx_fifo_count              ),
  .o_credit_error               ( credit_error                 ),
  .i_tx_clk_divide              ( i_tx_clk_divide_val          ),
  .o_credit_count_out           ( o_credit_count               ),
  .o_outstanding_count_out      ( o_outstnding_count           ),
  .i_space_wire_reset           ( space_wire_reset_out_signal  ),
  .o_tx_eep_async               ( tx_eep_async                 ),
  .o_tx_eop_async               ( tx_eop_async                 ),
  .o_tx_byte_async              ( tx_byte_async                )
);
//------------------------------------------------------------------------------
space_wire_state_machine       inst2_space_wire_state_machine
(
  .i_clk                       ( i_clk                        ),
  .i_rx_clk                    ( i_rx_clk                     ),
  .i_reset                     ( i_reset                      ),
  .i_after_12p8_us             ( after_12p8_us                ),
  .i_after_6p4_us              ( after_6p4_us                 ),
  .i_link_start                ( i_link_start                 ),
  .i_link_disable              ( i_link_disable               ),
  .i_auto_start                ( i_auto_start                 ),
  .o_tx_en                     ( tx_en                        ),
  .o_send_nulls                ( send_nulls                   ),
  .o_send_fcts                 ( send_fcts                    ),
  .o_send_n_character          ( send_n_char                  ),
  .o_send_time_codes           ( send_time_code               ),
  .i_got_fct                   ( got_fct                      ),
  .i_got_time_code             ( got_time_code                ),
  .i_got_n_character           ( got_n_char                   ),
  .i_got_null                  ( got_null                     ),
  .i_got_bit                   ( got_bit                      ),
  .i_credit_error              ( credit_error                 ),
  .i_rx_error                  ( rx_error                     ),
  .o_rx_en                     ( rx_en                        ),
  .o_char_sequence_error       ( char_sequence_error          ),
  .o_space_wire_reset_out      ( space_wire_reset_out_signal  ),
  .i_fifo_available            ( i_fifo_available             ),
  .o_timer_6p4_us_reset        ( timer_6p4_us_reset           ),
  .o_timer_12p8_us_start       ( timer_12p8_us_start          ),
  .o_link_up_transition_sync   ( link_up_tx_sync              ),
  .o_link_down_transition_sync ( link_down_tx_sync            ),
  .o_link_up_en                ( link_up_en                   ),
  .o_null_sync                 ( null_sync                    ),
  .o_fct_sync                  ( fct_sync                     )
);
//------------------------------------------------------------------------------
space_wire_timer 
#(
  .C_TIMER_6_4_US_VAL          ( C_TIMER_6_4_US_VAL  ),
  .C_TIMER_12_8_US_VAL         ( C_TIMER_12_8_US_VAL )
)
inst3_space_wire_timer 
(
  .i_clk                       ( i_clk                ),
  .i_reset                     ( i_reset              ),
  .i_timer_6p4_us_reset        ( timer_6p4_us_reset   ),
  .i_timer_12p8_us_start       ( timer_12p8_us_start  ),
  .o_after_6p4_us              ( after_6p4_us         ),
  .o_after_12p8_us             ( after_12p8_us        )
);
//------------------------------------------------------------------------------
space_wire_stat_info      inst4_space_wire_stat_info
(
  .i_clk                  ( i_clk              ),
  .i_reset                ( i_reset            ),
  .i_stat_clear           ( i_stat_info_clear  ),
  .i_tx_clk               ( i_tx_clk           ),
  .i_rx_clk               ( i_rx_clk           ),
  .i_rx_eep_async         ( rx_eep_async       ),
  .i_rx_eop_async         ( rx_eop_async       ),
  .i_rx_byte_async        ( rx_byte_async      ),
  .i_tx_eep_async         ( tx_eep_async       ),
  .i_tx_eop_async         ( tx_eop_async       ),
  .i_tx_byte_async        ( tx_byte_async      ),
  .i_link_up_transition   ( link_up_tx_sync    ),
  .i_link_down_transition ( link_down_tx_sync  ),
  .i_link_up_en           ( link_up_en         ),
  .i_null_sync            ( null_sync          ),
  .i_fct_sync             ( fct_sync           ),
  .o_stat_info_0          ( o_stat_info_0      ),
  .o_stat_info_1          ( o_stat_info_1      ),
  .o_stat_info_2          ( o_stat_info_2      ),
  .o_stat_info_3          ( o_stat_info_3      ),
  .o_stat_info_4          ( o_stat_info_4      ),
  .o_stat_info_5          ( o_stat_info_5      ),
  .o_stat_info_6          ( o_stat_info_6      ),
  .o_stat_info_7          ( o_stat_info_7      ),
  .o_char_mon             ( char_mon           )
);
//------------------------------------------------------------------------------
space_wire_time_code_control     inst5_space_wire_time_code_control
(
  .i_clk                         ( i_clk                ),
  .i_reset                       ( i_reset              ),
  .i_rx_clk                      ( i_rx_clk             ),
  .i_got_time_code               ( got_time_code        ),
  .i_rx_time_code                ( rx_time_code_out     ),
  .o_time_out                    ( o_time_out           ),
  .o_control_flags_out           ( o_control_flags_out  ),
  .o_tick_out                    ( o_tick_out           )
);
//------------------------------------------------------------------------------
assign o_rx_fifo_wr_en1         = rx_fifo_wr_en1;
assign rx_fifo_wr_en1           = rx_fifo_wr_en0 & send_n_char;
assign got_bit                  = ~rx_off;
assign o_space_wire_reset_out   = space_wire_reset_out_signal;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
//  Define status signal as LinkStatus or ErrorStatus.
//==============================================================================
assign o_link_status[0]     = tx_en;
assign o_link_status[1]     = rx_en;
assign o_link_status[2]     = send_nulls;
assign o_link_status[3]     = send_fcts;
assign o_link_status[4]     = send_n_char;
assign o_link_status[5]     = send_time_code;
assign o_link_status[6]     = 1'b0;
assign o_link_status[7]     = space_wire_reset_out_signal;
assign o_link_status[15:8]  = {1'b0, char_mon};
assign o_error_status[0]    = char_sequence_error;
// sequence.
assign o_error_status[1]    = credit_error;
// credit.
assign o_error_status[2]    = rx_error;
// rx_error(=parity, discon or escape error)
assign o_error_status[3]    = 1'b0;
assign o_error_status[4]    = parity_error;
//  parity.
assign o_error_status[5]    = disconnect_error;
//  disconnect.
assign o_error_status[6]    = escape_error;
//  escape.
assign o_error_status[7]    = 1'b0;
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_link_interface

