//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_rx 
#(
  parameter      C_DISCONNECT_CNT_VAL      = 141
)
(
  input    wire                 i_space_wire_strobe_in,
  input    wire                 i_space_wire_data_in,
  output   wire    [8:0]        o_rx_data_out,
  output   wire                 o_rx_data_valid_out,
  output   wire    [7:0]        o_rx_time_code_out,
  output   wire                 o_rx_time_code_valid_out,
  output   wire                 o_rx_n_char_out,
  output   wire                 o_rx_fct_out,
  output   wire                 o_rx_null_out,
  output   wire                 o_rx_eep_out,
  output   wire                 o_rx_eop_out,
  output   wire                 o_rx_off_out,
  output   wire                 o_rx_error_out,
  output   wire                 o_parity_error_out,
  output   wire                 o_escape_error_out,
  output   wire                 o_disconnect_error_out,
  input    wire                 i_space_wire_reset,
  output   wire                 o_rx_fifo_wr_en,
  input    wire                 i_rx_en,
  input    wire                 i_rx_clk
);
//------------------------------------------------------------------------------
reg     [7:0]    data_reg;
reg              parity;
reg              esc_flag;
reg     [1:0]    space_wire_sync;
reg     [3:0]    bit_count;
reg     [7:0]    link_time_out_counter;
reg              disconnect_error_out;
reg              parity_error_out;
reg              escape_error_out;
reg              command_flag;
reg              data_flag;
//------------------------------------------------------------------------------
// TYPE spaceWireStateMachine:
localparam SM_IDLE        = 0;
localparam SM_OFF         = 1;
localparam SM_EVEN0       = 2;
localparam SM_EVEN1       = 3;
localparam SM_WAIT_EVEN   = 4;
localparam SM_ODD0        = 5;
localparam SM_ODD1        = 6;
localparam SM_WAIT_ODD    = 7;
//------------------------------------------------------------------------------
reg     [2:0]    state_space_wire;
reg              rx_eop_out;
reg              rx_eep_out;
reg              rx_data_valid_out;
reg     [8:0]    rx_data_out;
reg     [7:0]    rx_time_code_out;
reg              rx_time_code_valid_out;
wire             rx_n_char_out;
reg              rx_fct_out;
reg              rx_null_out;
wire             rx_off_out;
wire             rx_error_out;
reg              rx_fifo_wr_en;
//------------------------------------------------------------------------------
reg              space_wire_data_in_z0;
reg              space_wire_data_in_z1;
reg              space_wire_strobe_in_z0;
reg              space_wire_strobe_in_z1;
//------------------------------------------------------------------------------
initial 
  begin : process_4
    rx_data_out       = {9{1'b0}};
    rx_time_code_out  = 8'h00;
  end
//------------------------------------------------------------------------------
assign o_rx_data_out              = rx_data_out;
assign o_rx_time_code_out         = rx_time_code_out;
assign o_rx_time_code_valid_out   = rx_time_code_valid_out;
assign o_rx_n_char_out            = rx_n_char_out;
assign o_rx_fct_out               = rx_fct_out;
assign o_rx_null_out              = rx_null_out;
assign o_rx_off_out               = rx_off_out;
assign o_rx_error_out             = rx_error_out;
assign o_rx_fifo_wr_en            = rx_fifo_wr_en;
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// ECSS-E-ST-50-12C 8.4.4 Receiver.
//==============================================================================
//---
//---
//---
//==============================================================================
// synchronize DS signal to the i_rx_clk.
//==============================================================================
always @(posedge i_rx_clk)
  begin : s_strobe_in
    // exclusion of metastability
    space_wire_data_in_z0     <= i_space_wire_data_in;
    space_wire_data_in_z1     <= space_wire_data_in_z0;
    space_wire_strobe_in_z0   <= i_space_wire_strobe_in;
    space_wire_strobe_in_z1   <= space_wire_strobe_in_z0;
    // combination
    space_wire_sync           <= {space_wire_strobe_in_z1, space_wire_data_in_z1};
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Detect a change of the DS signal.
//==============================================================================
always @(posedge i_rx_clk or posedge i_space_wire_reset or posedge disconnect_error_out)
  begin : s_detect_ds
    if ( i_space_wire_reset | disconnect_error_out )
      begin
        state_space_wire <= SM_IDLE;
      end
    else
      begin
        if ( i_rx_en )
          begin
            //------------------------------------------
            if ( state_space_wire == SM_IDLE )
              begin
                if ( space_wire_sync == 2'b00 )
                  begin
                    state_space_wire      <= SM_OFF;
                  end
              end
            //------------------------------------------
            else if ( state_space_wire == SM_OFF )
              begin
                if ( space_wire_sync == 2'b10)
                  begin
                    state_space_wire      <= SM_ODD0;
                  end
              end
            //------------------------------------------
            else if ( state_space_wire == SM_EVEN1    | 
                      state_space_wire == SM_EVEN0    | 
                      state_space_wire == SM_WAIT_ODD )
              begin
                if ( space_wire_sync == 2'b10 )
                  begin
                    state_space_wire      <= SM_ODD0;
                  end
                else if ( space_wire_sync == 2'b01 )
                  begin
                    state_space_wire      <= SM_ODD1;
                  end
                else
                  begin
                    state_space_wire      <= SM_WAIT_ODD;
                  end
              end
            //------------------------------------------
            else if ( state_space_wire == SM_ODD1      | 
                      state_space_wire == SM_ODD0      | 
                      state_space_wire == SM_WAIT_EVEN )
              begin
                if ( space_wire_sync == 2'b00 )
                  begin
                    state_space_wire      <= SM_EVEN0;
                  end
                else if ( space_wire_sync == 2'b11 )
                  begin
                    state_space_wire      <= SM_EVEN1;
                  end
                else
                  begin
                    state_space_wire      <= SM_WAIT_EVEN;
                  end
              end
            //------------------------------------------
            else
              begin
                state_space_wire          <= SM_IDLE;
              end
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
always @(posedge i_rx_clk)
  begin : s_data_decode
    //==========================================================================
    // Take the data into the shift register on the State transition 
    // of state_space_wire.
    //==========================================================================
    if ( i_rx_en )
      begin
        if ( state_space_wire == SM_OFF )
          begin
            data_reg    <= {8{1'b0}};
          end
        else if ( state_space_wire == SM_ODD1 | state_space_wire == SM_EVEN1 )
          begin
            data_reg    <= {1'b1, data_reg[7:1]};
          end
        else if ( state_space_wire == SM_ODD0 | state_space_wire == SM_EVEN0 )
          begin
            data_reg    <= {1'b0, data_reg[7:1]};
          end
      end
    else
      begin
        data_reg        <= {8{1'b0}};
      end
    //==========================================================================
    // ECSS-E-ST-50-12C 7.4 Parity for error detection.
    // Odd Parity.
    //==========================================================================
    if ( i_rx_en & !escape_error_out & !disconnect_error_out )
      begin
        if ( state_space_wire == SM_OFF )
          begin
            parity                  <= 1'b0;
          end
        else if ( bit_count == 0 & state_space_wire == SM_EVEN1 )
          begin
            if ( parity )
              begin
                parity_error_out    <= 1'b1;
                parity              <= 1'b0;
              end
          end
        else if ( bit_count == 0 & state_space_wire == SM_EVEN0 )
          begin
            if ( !parity )
              begin
                parity_error_out    <= 1'b1;
              end
            else
              begin
                parity              <= 1'b0;
              end
          end
        else if ( state_space_wire == SM_ODD1 | state_space_wire == SM_EVEN1 )
          begin
            parity                  <= ~parity;
          end
      end
    else
      begin
        parity_error_out            <= 1'b0;
      end
    //==========================================================================
    // ECSS-E-ST-50-12C 8.5.3.7.2 Disconnect error.
    // Disconnect error is an error condition asserted
    // when the length of time since the last transition on
    // the D or S lines was longer than 850 ns nominal.
    //==========================================================================
    if ( i_rx_en & !escape_error_out & !parity_error_out )
      begin
        if ( state_space_wire == SM_WAIT_ODD  | 
             state_space_wire == SM_WAIT_EVEN )
          begin
            if ( link_time_out_counter < C_DISCONNECT_CNT_VAL )
              begin
                link_time_out_counter   <= link_time_out_counter + 1;
              end
            else
              begin
                disconnect_error_out    <= 1'b1;
              end
          end
        else if ( state_space_wire == SM_IDLE )
          begin
            link_time_out_counter       <= 8'h00;
          end
        else if ( state_space_wire == SM_ODD1  | 
                  state_space_wire == SM_EVEN1 | 
                  state_space_wire == SM_ODD0  | 
                  state_space_wire == SM_EVEN0 )
            begin
              link_time_out_counter     <= 8'h00;
            end
      end
    else
      begin
        disconnect_error_out            <= 1'b0;
        link_time_out_counter           <= 8'h00;
      end
    //==========================================================================
    // ECSS-E-ST-50-12C 4.4 Character level
    // ECSS-E-ST-50-12C 7.2 Data characters
    // Discriminate the data character or the  the control character by the Data 
    // Control Flag.
    //==========================================================================
    if ( i_rx_en )
      begin
        if ( state_space_wire == SM_IDLE )
          begin
            command_flag  <= 1'b0;
            data_flag     <= 1'b0;
          end
        else if ( bit_count == 0 & state_space_wire == SM_EVEN0 )
          begin
            command_flag  <= 1'b0;
            data_flag     <= 1'b1;
          end
        else if ( bit_count == 0 & state_space_wire == SM_EVEN1 )
          begin
            command_flag  <= 1'b1;
            data_flag     <= 1'b0;
          end
      end
    else
      begin
        command_flag      <= 1'b0;
        data_flag         <= 1'b0;
      end
    //==========================================================================
    // Increment bit of character corresponding by state transition of 
    // state_space_wire.
    //==========================================================================
    if ( i_rx_en & !escape_error_out & !disconnect_error_out )
      begin
        if ( state_space_wire == SM_IDLE | state_space_wire == SM_OFF)
          begin
            bit_count       <= 4'h0;
          end
        else if ( state_space_wire == SM_EVEN1 | state_space_wire == SM_EVEN0 )
          begin
            if ( bit_count == 1 & command_flag )
              begin
                bit_count   <= 4'h0;
              end
            else if ( bit_count == 4 & !command_flag )
              begin
                bit_count   <= 4'h0;
              end
            else
              begin
                bit_count   <= bit_count + 1;
              end
          end
      end
    else
      begin
        bit_count           <= 4'h0;
      end
    //==========================================================================
    // ECSS-E-ST-50-12C 7.3 Control characters and control codes.
    // Discriminate  Data character, Control code and Time corde, and write to 
    // Receive buffer
    //==========================================================================
    if ( i_rx_en )
      begin
        if ( bit_count == 0 & ( state_space_wire == SM_ODD0 | 
                                state_space_wire == SM_ODD1 ) )
          begin
            if ( data_flag )
              begin
                if ( esc_flag )
                  begin
                    // Time Code Receive.
                    rx_time_code_out    <= data_reg;
                  end
                else
                  begin
                    // Data Receive.
                    rx_data_out         <= {1'b0, data_reg};
                    rx_fifo_wr_en       <= 1'b1;
                  end
              end
            else if ( command_flag )
              begin
                if ( data_reg[7:6] == 2'b10 )
                  begin
                    // EOP
                    rx_data_out         <= {1'b1, 8'b00000000};
                  end
                else if ( data_reg[7:6] == 2'b01 )
                  begin
                    // EEP
                    rx_data_out         <= {1'b1, 8'b00000001};
                  end
                if ( !esc_flag & ( data_reg[7:6] == 2'b10 | 
                                   data_reg[7:6] == 2'b01 ) )
                  begin
                    // EOP EEP Receive.
                    rx_fifo_wr_en       <= 1'b1;
                  end
              end
          end
        else
          begin
            rx_fifo_wr_en               <= 1'b0;
          end
      end
    //==========================================================================
    // ECSS-E-ST-50-12C 7.3 Control characters and control codes.
    // ECSS-E-ST-50-12C 8.5.3.7.4 Escape error.
    // Receive DataCharacter, ControlCode and TimeCode.
    //==========================================================================
    if ( i_rx_en & !disconnect_error_out & !parity_error_out )
      begin
        if ( bit_count == 0 & ( state_space_wire == SM_ODD0 | 
                                state_space_wire == SM_ODD1 ) )
          begin
            if ( command_flag )
              begin
                case ( data_reg[7:6] )
                  //============================================================
                  // ECSS-E-ST-50-12C 8.5.3.2 gotNULL.
                  // ECSS-E-ST-50-12C 8.5.3.3 gotFCT.
                  //============================================================
                  // FCT Receive or Null Receive.
                  2'b00:
                    begin
                      if ( esc_flag )
                        begin
                          rx_null_out       <= 1'b1;
                          esc_flag          <= 1'b0;
                        end
                      else
                        begin
                          rx_fct_out        <= 1'b1;
                        end
                    end
                  // ESC Receive.
                  2'b11:
                    begin
                      if ( esc_flag )
                        begin
                          escape_error_out  <= 1'b1;
                        end
                      else
                        begin
                          esc_flag          <= 1'b1;
                        end
                    end
                  // EOP Receive.
                  2'b10:
                    begin
                      if ( esc_flag )
                        begin
                          escape_error_out  <= 1'b1;
                        end
                      else
                        begin
                          rx_eop_out        <= 1'b1;
                        end
                     end
                  // EEP Receive.
                  2'b01:
                    begin
                      if ( esc_flag )
                        begin
                          escape_error_out  <= 1'b1;
                        end
                      else
                        begin
                          rx_eep_out        <= 1'b1;
                        end
                    end
                  default:
                    ;
                endcase
              end
            //==================================================================
            // ECSS-E-ST-50-12C 8.5.3.5 gotTime-Code.
            // ECSS-E-ST-50-12C 8.5.3.4 gotN-Char.
            //==================================================================
            else if ( data_flag )
              begin
                if ( esc_flag )
                  begin
                    // TimeCode_Receive.
                    rx_time_code_valid_out  <= 1'b1;
                    esc_flag                <= 1'b0;
                  end
                else
                  begin
                    // N-Char_Receive.
                    rx_data_valid_out       <= 1'b1;
                  end
              end
          end
        //======================================================================
        // Clear the previous Receive flag before receiving data.
        //======================================================================
         
        else if ( bit_count == 1 & ( state_space_wire == SM_ODD0 | 
                                     state_space_wire == SM_ODD1 ) )
          begin
            rx_data_valid_out       <= 1'b0;
            rx_time_code_valid_out  <= 1'b0;
            rx_null_out             <= 1'b0;
            rx_fct_out              <= 1'b0;
            rx_eop_out              <= 1'b0;
            rx_eep_out              <= 1'b0;
          end
        else if ( state_space_wire == SM_IDLE )
          begin
            rx_data_valid_out       <= 1'b0;
            rx_time_code_valid_out  <= 1'b0;
            rx_null_out             <= 1'b0;
            rx_fct_out              <= 1'b0;
            rx_eop_out              <= 1'b0;
            rx_eep_out              <= 1'b0;
            escape_error_out        <= 1'b0;
            esc_flag                <= 1'b0;
          end
      end
    else
      begin
        rx_data_valid_out           <= 1'b0;
        rx_time_code_valid_out      <= 1'b0;
        rx_null_out                 <= 1'b0;
        rx_fct_out                  <= 1'b0;
        rx_eop_out                  <= 1'b0;
        rx_eep_out                  <= 1'b0;
        escape_error_out            <= 1'b0;
        esc_flag                    <= 1'b0;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//------------------------------------------------------------------------------
assign rx_off_out              = ( state_space_wire == SM_OFF ) ? 1'b1 : 1'b0;
//------------------------------------------------------------------------------
assign rx_error_out            = ( disconnect_error_out | 
                                   parity_error_out     | 
                                   escape_error_out     ) ? 1'b1 : 1'b0;
//------------------------------------------------------------------------------
assign rx_n_char_out           = ( rx_eop_out           | 
                                   rx_eep_out           | 
                                   rx_data_valid_out    ) ? 1'b1 : 1'b0;
//------------------------------------------------------------------------------
assign o_rx_data_valid_out     = rx_data_valid_out;
assign o_rx_eop_out            = rx_eop_out;
assign o_rx_eep_out            = rx_eep_out;
assign o_parity_error_out      = parity_error_out;
assign o_escape_error_out      = escape_error_out;
assign o_disconnect_error_out  = disconnect_error_out;
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_rx

