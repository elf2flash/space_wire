//------------------------------------------------------------------------------
`timescale 1 ps / 1 ps // timescale for following modules
//------------------------------------------------------------------------------
module tb_space_wire 
(
);
//------------------------------------------------------------------------------
localparam  [31:0]   C_PAUSE_RST_0        = 100;
localparam  [31:0]   C_PAUSE_RST_1        = 150;
localparam  [31:0]   C_PAUSE_AFTER_RST_0  = 10;
localparam  [31:0]   C_PAUSE_AFTER_RST_1  = 17;
localparam  [31:0]   C_TICK_IN_CNT_VAL_0  = 530;
localparam  [31:0]   C_TICK_IN_CNT_VAL_1  = 678;
localparam  [5:0]    C_TX_CLK_DIVIDE_VAL  = 6'b001001;
//---
localparam  [31:0]   C_PAUSE_DATA_SEND_0  = 4918;
localparam  [31:0]   C_PAUSE_DATA_SEND_1  = 6154;
localparam  [31:0]   C_DATA_SEND_COUNT_0  = 23;
localparam  [31:0]   C_DATA_SEND_COUNT_1  = 45;
//------------------------------------------------------------------------------
reg                  sw0_i_reset;
reg                  sw0_i_tx_fifo_wr_en;
reg     [8:0]        sw0_i_tx_fifo_data_in;
wire                 sw0_o_tx_fifo_full;
wire    [5:0]        sw0_o_tx_fifo_data_count;
reg                  sw0_i_rx_fifo_rd_en;
wire    [8:0]        sw0_o_rx_fifo_data_out;
wire                 sw0_o_rx_fifo_full;
wire                 sw0_o_rx_fifo_empty;
wire    [5:0]        sw0_o_rx_fifo_data_count;
reg                  sw0_i_tick_in;
reg     [5:0]        sw0_i_time_in;
reg     [1:0]        sw0_i_control_flags_in;
wire                 sw0_o_tick_out;
wire    [5:0]        sw0_o_time_out;
wire    [1:0]        sw0_o_control_flags_out;
reg                  sw0_i_link_start;
reg                  sw0_i_link_disable;
reg                  sw0_i_auto_start;
wire    [15:0]       sw0_o_link_status;
wire    [7:0]        sw0_o_error_status;
reg     [5:0]        sw0_i_tx_clk_divide_val;
wire    [5:0]        sw0_o_credit_count;
wire    [5:0]        sw0_o_outstanding_count;
wire                 sw0_o_tx_activity;
wire                 sw0_o_rx_activity;
wire                 sw0_o_space_wire_data_out;
wire                 sw0_o_space_wire_strobe_out;
reg                  sw0_o_space_wire_data_in;
reg                  sw0_o_space_wire_strobe_in;
reg                  sw0_i_stat_info_clear;
wire    [7:0]        sw0_o_stat_info_0;
wire    [7:0]        sw0_o_stat_info_1;
wire    [7:0]        sw0_o_stat_info_2;
wire    [7:0]        sw0_o_stat_info_3;
wire    [7:0]        sw0_o_stat_info_4;
wire    [7:0]        sw0_o_stat_info_5;
wire    [7:0]        sw0_o_stat_info_6;
wire    [7:0]        sw0_o_stat_info_7;
//------------------------------------------------------------------------------
reg                  sw1_i_reset;
reg                  sw1_i_tx_fifo_wr_en;
reg     [8:0]        sw1_i_tx_fifo_data_in;
wire                 sw1_o_tx_fifo_full;
wire    [5:0]        sw1_o_tx_fifo_data_count;
reg                  sw1_i_rx_fifo_rd_en;
wire    [8:0]        sw1_o_rx_fifo_data_out;
wire                 sw1_o_rx_fifo_full;
wire                 sw1_o_rx_fifo_empty;
wire    [5:0]        sw1_o_rx_fifo_data_count;
reg                  sw1_i_tick_in;
reg     [5:0]        sw1_i_time_in;
reg     [1:0]        sw1_i_control_flags_in;
wire                 sw1_o_tick_out;
wire    [5:0]        sw1_o_time_out;
wire    [1:0]        sw1_o_control_flags_out;
reg                  sw1_i_link_start;
reg                  sw1_i_link_disable;
reg                  sw1_i_auto_start;
wire    [15:0]       sw1_o_link_status;
wire    [7:0]        sw1_o_error_status;
reg     [5:0]        sw1_i_tx_clk_divide_val;
wire    [5:0]        sw1_o_credit_count;
wire    [5:0]        sw1_o_outstanding_count;
wire                 sw1_o_tx_activity;
wire                 sw1_o_rx_activity;
wire                 sw1_o_space_wire_data_out;
wire                 sw1_o_space_wire_strobe_out;
reg                  sw1_o_space_wire_data_in;
reg                  sw1_o_space_wire_strobe_in;
reg                  sw1_i_stat_info_clear;
wire    [7:0]        sw1_o_stat_info_0;
wire    [7:0]        sw1_o_stat_info_1;
wire    [7:0]        sw1_o_stat_info_2;
wire    [7:0]        sw1_o_stat_info_3;
wire    [7:0]        sw1_o_stat_info_4;
wire    [7:0]        sw1_o_stat_info_5;
wire    [7:0]        sw1_o_stat_info_6;
wire    [7:0]        sw1_o_stat_info_7;
//------------------------------------------------------------------------------
initial
  begin
    sw0_i_reset              = 1'b1;
    sw0_i_tx_fifo_wr_en      = 1'b0;
    sw0_i_tx_fifo_data_in    = 8'b00000000;
    sw0_i_rx_fifo_rd_en      = 1'b0;
    sw0_i_tick_in            = 1'b0;
    sw0_i_time_in            = 6'b000000;
    sw0_i_control_flags_in   = 2'b00;
    sw0_i_link_start         = 1'b0;
    sw0_i_link_disable       = 1'b0;
    sw0_i_auto_start         = 1'b0;
    sw0_i_tx_clk_divide_val  = C_TX_CLK_DIVIDE_VAL;
    sw0_i_stat_info_clear    = 1'b0;
    //---
    sw1_i_reset              = 1'b1;
    sw1_i_tx_fifo_wr_en      = 1'b0;
    sw1_i_tx_fifo_data_in    = 8'b00000000;
    sw1_i_rx_fifo_rd_en      = 1'b0;
    sw1_i_tick_in            = 1'b0;
    sw1_i_time_in            = 6'b000000;
    sw1_i_control_flags_in   = 2'b00;
    sw1_i_link_start         = 1'b0;
    sw1_i_link_disable       = 1'b0;
    sw1_i_auto_start         = 1'b0;
    sw1_i_tx_clk_divide_val  = C_TX_CLK_DIVIDE_VAL;
    sw1_i_stat_info_clear    = 1'b0;
  end
//------------------------------------------------------------------------------
reg                  clk_100;
reg                  clk_50;
reg                  clk_166;
wire                 clock_system_0;
wire                 clock_system_1;
wire                 tx_clk_0;
wire                 tx_clk_1;
wire                 rx_clk_0;
wire                 rx_clk_1;
reg     [31:0]       clock_system_rst_cnt_0;
reg     [31:0]       clock_system_rst_cnt_1;
reg     [31:0]       link_start_cnt_0;
reg     [31:0]       link_start_cnt_1;
reg     [3:0]        link_state_tb_0;
reg     [3:0]        link_state_tb_1;
reg     [31:0]       tick_in_cnt_0;
reg     [31:0]       tick_in_cnt_1;
reg     [31:0]       data_send_cnt_0;
reg     [3:0]        state_data_send_0;
reg     [31:0]       data_send_cnt_1;
reg     [3:0]        state_data_send_1;
reg     [3:0]        state_rd_data_0;
reg     [3:0]        state_rd_data_1;
//------------------------------------------------------------------------------
initial  clk_100  = 0;
initial  clk_50   = 0;
initial  clk_166  = 0;
// 100 MHz
always  #5000  clk_100 = ~clk_100;
//  50 MHz
always #10000  clk_50 = ~clk_50;
// 166 MHz
always  #3000  clk_166 = ~clk_166;
//------------------------------------------------------------------------------
assign  clock_system_0  = clk_50;
assign  clock_system_1  = clk_50;
assign  tx_clk_0        = clk_100;
assign  tx_clk_1        = clk_100;
assign  rx_clk_0        = clk_166;
assign  rx_clk_1        = clk_166;
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
always @(posedge clock_system_1)
  begin : s_ds_z
    sw1_o_space_wire_data_in      <= sw0_o_space_wire_data_out;
    sw1_o_space_wire_strobe_in    <= sw0_o_space_wire_strobe_out;
    //---
    sw0_o_space_wire_data_in      <= sw1_o_space_wire_data_out;
    sw0_o_space_wire_strobe_in    <= sw1_o_space_wire_strobe_out;
  end
//==============================================================================
// Reset simulation.
//==============================================================================
initial clock_system_rst_cnt_0  = 32'h00000000;
//---
always @(posedge clock_system_0)
  begin : s_reset_0
    clock_system_rst_cnt_0        <= clock_system_rst_cnt_0 + 1;
    if ( clock_system_rst_cnt_0 < C_PAUSE_RST_0 )
      begin
        sw0_i_reset							<= 1'b1;
      end
    else
      begin
        sw0_i_reset							<= 1'b0;
      end
  end
//------------------------------------------------------------------------------
initial clock_system_rst_cnt_1  = 32'h00000000;
//---
always @(posedge clock_system_1)
  begin : s_reset_1
    clock_system_rst_cnt_1        <= clock_system_rst_cnt_1 + 1;
    if ( clock_system_rst_cnt_1 < C_PAUSE_RST_1 )
      begin
        sw1_i_reset							<= 1'b1;
      end
    else
      begin
        sw1_i_reset							<= 1'b0;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Link start simulation.
//==============================================================================
initial link_start_cnt_0         = 32'h00000000;
initial link_state_tb_0          = 4'h0;
//---
always @(posedge clock_system_0)
  begin : s_link_start_0
    sw0_i_link_disable                  <= 1'b0;
    //---------------------------------------------
    // Wait reset down
    if ( link_state_tb_0 == 4'h0 )
      begin
        sw0_i_link_start                <= 1'b0;
        sw0_i_auto_start                <= 1'b0;
        if ( !sw0_i_reset )
          begin
            link_state_tb_0             <= 4'h1;
          end
      end
    //---------------------------------------------
    // Pause after reset
    else if ( link_state_tb_0 == 4'h1 )
      begin
        link_start_cnt_0                <= link_start_cnt_0 + 1;
        if ( link_start_cnt_0 > C_PAUSE_AFTER_RST_0 )
          begin
            link_state_tb_0							<= 4'h2;
          end
      end
    //---------------------------------------------
    // Start link 0
    else if ( link_state_tb_0 == 4'h2 )
      begin
        sw0_i_link_start                <= 1'b1;
        sw0_i_auto_start                <= 1'b1;
        if ( sw0_i_reset )
          begin
            link_state_tb_0             <= 4'h0;
          end
      end
  end
//------------------------------------------------------------------------------
initial link_start_cnt_1  = 32'h00000000;
initial link_state_tb_1   = 4'h0;
//---
always @(posedge clock_system_1)
  begin : s_link_start_1
    sw1_i_link_disable                  <= 1'b0;
    //---------------------------------------------
    // Wait reset down
    if ( link_state_tb_1 == 4'h0 )
      begin
        sw1_i_link_start                <= 1'b0;
        sw1_i_auto_start                <= 1'b0;
        if ( !sw1_i_reset )
          begin
            link_state_tb_1             <= 4'h1;
          end
      end
    //---------------------------------------------
    // Pause after reset
    else if ( link_state_tb_1 == 4'h1 )
      begin
        link_start_cnt_1                <= link_start_cnt_1 + 1;
        if ( link_start_cnt_1 > C_PAUSE_AFTER_RST_1 )
          begin
            link_state_tb_1							<= 4'h2;
          end
      end
    //---------------------------------------------
    // Start link 1
    else if ( link_state_tb_1 == 4'h2 )
      begin
        sw1_i_link_start                <= 1'b1;
        sw1_i_auto_start                <= 1'b1;
        if ( sw1_i_reset )
          begin
            link_state_tb_1             <= 4'h0;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// TickIn And TimeIn simulation.
//==============================================================================
initial tick_in_cnt_0              = 32'h00000000;
initial sw0_i_time_in              = 6'b000000;
//---
always @(posedge tx_clk_0)
  begin : s_tick_in_0
    sw0_i_tick_in                 <= 1'b0;
    if ( sw0_i_reset )
      begin
        tick_in_cnt_0             <= 1'b0;
        sw0_i_time_in             <= 6'b000000;
      end
    else
      begin
        tick_in_cnt_0             <= tick_in_cnt_0 + 1;
        if ( tick_in_cnt_0 >= C_TICK_IN_CNT_VAL_0 )
          begin
            tick_in_cnt_0         <= 32'h00000000;
            sw0_i_tick_in         <= 1'b1;
            sw0_i_time_in         <= sw0_i_time_in + 1;
          end
      end
  end
//------------------------------------------------------------------------------
initial tick_in_cnt_1              = 32'h00000000;
initial sw1_i_time_in              = 6'b000000;
//---
always @(posedge tx_clk_1)
  begin : s_tick_in_1
    sw1_i_tick_in                 <= 1'b0;
    if ( sw1_i_reset )
      begin
        tick_in_cnt_1             <= 1'b0;
        sw1_i_time_in             <= 6'b000000;
      end
    else
      begin
        tick_in_cnt_1             <= tick_in_cnt_1 + 1;
        if ( tick_in_cnt_1 >= C_TICK_IN_CNT_VAL_1 )
          begin
            tick_in_cnt_1         <= 32'h00000000;
            sw1_i_tick_in         <= 1'b1;
            sw1_i_time_in         <= sw1_i_time_in + 1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Data send simulation.
//==============================================================================
initial data_send_cnt_0              = 32'h00000000;
initial state_data_send_0            = 4'h0;
//---
always @(posedge clock_system_0)
  begin : s_data_send_0
    sw0_i_tx_fifo_wr_en             <= 1'b0;
    if ( state_data_send_0 == 4'h0 )
      begin
        // sw0_o_link_status[0] - EnableTransmit
        if ( sw0_o_link_status[0] )
          begin
            data_send_cnt_0           <= data_send_cnt_0 + 1;
            if ( data_send_cnt_0 > C_PAUSE_DATA_SEND_0 )
              begin
                data_send_cnt_0       <= 32'h00000000;
                state_data_send_0     <= 4'h1;
              end
          end
      end
    else if ( state_data_send_0 == 4'h1 )
      begin
        if ( !sw0_o_tx_fifo_full & sw0_o_link_status[0] & data_send_cnt_0 < C_DATA_SEND_COUNT_0 )
          begin
            data_send_cnt_0         <= data_send_cnt_0 + 1;
            sw0_i_tx_fifo_wr_en     <= 1'b1;
            sw0_i_tx_fifo_data_in   <= sw0_i_tx_fifo_data_in + 1;
          end
        else if ( !sw0_o_link_status[0] | data_send_cnt_0 == C_DATA_SEND_COUNT_0 )
          begin
            data_send_cnt_0         <= 32'h00000000;
            state_data_send_0       <= 4'h0;
          end
      end
  end
//------------------------------------------------------------------------------
initial data_send_cnt_1              = 32'h00000000;
initial state_data_send_1            = 4'h0;
//---
always @(posedge clock_system_1)
  begin : s_data_send_1
    sw1_i_tx_fifo_wr_en             <= 1'b0;
    if ( state_data_send_1 == 4'h0 )
      begin
        // sw1_o_link_status[0] - EnableTransmit
        if ( sw1_o_link_status[0] )
          begin
            data_send_cnt_1           <= data_send_cnt_1 + 1;
            if ( data_send_cnt_1 > C_PAUSE_DATA_SEND_1 )
              begin
                data_send_cnt_1       <= 32'h00000000;
                state_data_send_1     <= 4'h1;
              end
          end
      end
    else if ( state_data_send_1 == 4'h1 )
      begin
        if ( !sw1_o_tx_fifo_full & sw1_o_link_status[0] & data_send_cnt_1 < C_DATA_SEND_COUNT_1 )
          begin
            data_send_cnt_1         <= data_send_cnt_1 + 1;
            sw1_i_tx_fifo_wr_en     <= 1'b1;
            sw1_i_tx_fifo_data_in   <= sw1_i_tx_fifo_data_in + 1;
          end
        else if ( !sw1_o_link_status[0] | data_send_cnt_1 == C_DATA_SEND_COUNT_1 )
          begin
            data_send_cnt_1         <= 32'h00000000;
            state_data_send_1       <= 4'h0;
          end
      end
  end
//==============================================================================
// Read rx FIFO 0
//==============================================================================
initial state_rd_data_0 = 4'h0;
//---
always @(posedge clock_system_0)
  begin : s_data_rd_0
    sw0_i_rx_fifo_rd_en             <= 1'b0;
    if ( state_rd_data_0 == 4'h0 )
      begin
        if ( !sw0_o_rx_fifo_empty )
          begin
            sw0_i_rx_fifo_rd_en     <= 1'b1;
            state_rd_data_0         <= 4'h1;
          end
      end
    else if ( state_rd_data_0 == 4'h1 )
      begin
        state_rd_data_0             <= 4'h2;
      end
    else if ( state_rd_data_0 == 4'h2 )
      begin
        state_rd_data_0             <= 4'h0;
      end
  end
//------------------------------------------------------------------------------
initial state_rd_data_1 = 4'h0;
//---
always @(posedge clock_system_1)
  begin : s_data_rd_1
    sw1_i_rx_fifo_rd_en             <= 1'b0;
    if ( state_rd_data_1 == 4'h0 )
      begin
        if ( !sw1_o_rx_fifo_empty )
          begin
            sw1_i_rx_fifo_rd_en     <= 1'b1;
            state_rd_data_1         <= 4'h1;
          end
      end
    else if ( state_rd_data_1 == 4'h1 )
      begin
        state_rd_data_1             <= 4'h2;
      end
    else if ( state_rd_data_1 == 4'h2 )
      begin
        state_rd_data_1             <= 4'h0;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
space_wire                    inst0_space_wire 
(
  .i_clk                      ( clock_system_0              ),
  .i_tx_clk                   ( tx_clk_0                    ),
  .i_rx_clk                   ( rx_clk_0                    ),
  .i_reset                    ( sw0_i_reset                 ),
  .i_tx_fifo_wr_en            ( sw0_i_tx_fifo_wr_en         ),
  .i_tx_fifo_data_in          ( sw0_i_tx_fifo_data_in       ),
  .o_tx_fifo_full             ( sw0_o_tx_fifo_full          ),
  .o_tx_fifo_data_count       ( sw0_o_tx_fifo_data_count    ),
  .i_rx_fifo_rd_en            ( sw0_i_rx_fifo_rd_en         ),
  .o_rx_fifo_data_out         ( sw0_o_rx_fifo_data_out      ),
  .o_rx_fifo_full             ( sw0_o_rx_fifo_full          ),
  .o_rx_fifo_empty            ( sw0_o_rx_fifo_empty         ),
  .o_rx_fifo_data_count       ( sw0_o_rx_fifo_data_count    ),
  .i_tick_in                  ( sw0_i_tick_in               ),
  .i_time_in                  ( sw0_i_time_in               ),
  .i_control_flags_in         ( sw0_i_control_flags_in      ),
  .o_tick_out                 ( sw0_o_tick_out              ),
  .o_time_out                 ( sw0_o_time_out              ),
  .o_control_flags_out        ( sw0_o_control_flags_out     ),
  .i_link_start               ( sw0_i_link_start            ),
  .i_link_disable             ( sw0_i_link_disable          ),
  .i_auto_start               ( sw0_i_auto_start            ),
  .o_link_status              ( sw0_o_link_status           ),
  .o_error_status             ( sw0_o_error_status          ),
  .i_tx_clk_divide_val        ( sw0_i_tx_clk_divide_val     ),
  .o_credit_count             ( sw0_o_credit_count          ),
  .o_outstanding_count        ( sw0_o_outstanding_count     ),
  .o_tx_activity              ( sw0_o_tx_activity           ),
  .o_rx_activity              ( sw0_o_rx_activity           ),
  .o_space_wire_data_out      ( sw0_o_space_wire_data_out   ),
  .o_space_wire_strobe_out    ( sw0_o_space_wire_strobe_out ),
  .o_space_wire_data_in       ( sw0_o_space_wire_data_in    ),
  .o_space_wire_strobe_in     ( sw0_o_space_wire_strobe_in  ),
  .i_stat_info_clear          ( sw0_i_stat_info_clear       ),
  .o_stat_info_0              ( sw0_o_stat_info_0           ),
  .o_stat_info_1              ( sw0_o_stat_info_1           ),
  .o_stat_info_2              ( sw0_o_stat_info_2           ),
  .o_stat_info_3              ( sw0_o_stat_info_3           ),
  .o_stat_info_4              ( sw0_o_stat_info_4           ),
  .o_stat_info_5              ( sw0_o_stat_info_5           ),
  .o_stat_info_6              ( sw0_o_stat_info_6           ),
  .o_stat_info_7              ( sw0_o_stat_info_7           )
);
//------------------------------------------------------------------------------
space_wire                    inst1_space_wire 
(
  .i_clk                      ( clock_system_1              ),
  .i_tx_clk                   ( tx_clk_1                    ),
  .i_rx_clk                   ( rx_clk_1                    ),
  .i_reset                    ( sw1_i_reset                 ),
  .i_tx_fifo_wr_en            ( sw1_i_tx_fifo_wr_en         ),
  .i_tx_fifo_data_in          ( sw1_i_tx_fifo_data_in       ),
  .o_tx_fifo_full             ( sw1_o_tx_fifo_full          ),
  .o_tx_fifo_data_count       ( sw1_o_tx_fifo_data_count    ),
  .i_rx_fifo_rd_en            ( sw1_i_rx_fifo_rd_en         ),
  .o_rx_fifo_data_out         ( sw1_o_rx_fifo_data_out      ),
  .o_rx_fifo_full             ( sw1_o_rx_fifo_full          ),
  .o_rx_fifo_empty            ( sw1_o_rx_fifo_empty         ),
  .o_rx_fifo_data_count       ( sw1_o_rx_fifo_data_count    ),
  .i_tick_in                  ( sw1_i_tick_in               ),
  .i_time_in                  ( sw1_i_time_in               ),
  .i_control_flags_in         ( sw1_i_control_flags_in      ),
  .o_tick_out                 ( sw1_o_tick_out              ),
  .o_time_out                 ( sw1_o_time_out              ),
  .o_control_flags_out        ( sw1_o_control_flags_out     ),
  .i_link_start               ( sw1_i_link_start            ),
  .i_link_disable             ( sw1_i_link_disable          ),
  .i_auto_start               ( sw1_i_auto_start            ),
  .o_link_status              ( sw1_o_link_status           ),
  .o_error_status             ( sw1_o_error_status          ),
  .i_tx_clk_divide_val        ( sw1_i_tx_clk_divide_val     ),
  .o_credit_count             ( sw1_o_credit_count          ),
  .o_outstanding_count        ( sw1_o_outstanding_count     ),
  .o_tx_activity              ( sw1_o_tx_activity           ),
  .o_rx_activity              ( sw1_o_rx_activity           ),
  .o_space_wire_data_out      ( sw1_o_space_wire_data_out   ),
  .o_space_wire_strobe_out    ( sw1_o_space_wire_strobe_out ),
  .o_space_wire_data_in       ( sw1_o_space_wire_data_in    ),
  .o_space_wire_strobe_in     ( sw1_o_space_wire_strobe_in  ),
  .i_stat_info_clear          ( sw1_i_stat_info_clear       ),
  .o_stat_info_0              ( sw1_o_stat_info_0           ),
  .o_stat_info_1              ( sw1_o_stat_info_1           ),
  .o_stat_info_2              ( sw1_o_stat_info_2           ),
  .o_stat_info_3              ( sw1_o_stat_info_3           ),
  .o_stat_info_4              ( sw1_o_stat_info_4           ),
  .o_stat_info_5              ( sw1_o_stat_info_5           ),
  .o_stat_info_6              ( sw1_o_stat_info_6           ),
  .o_stat_info_7              ( sw1_o_stat_info_7           )
);
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_time_code_control