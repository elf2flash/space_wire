//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
// ECSS-E-ST-50-12C 8.4.4 Receiver.
//------------------------------------------------------------------------------
module space_wire_rx 
#(
  parameter      C_DISCONNECT_CNT_VAL      = 141
)
(
  // Input SpaceWire DS signal
  input    wire            i_space_wire_strobe_in,   // Input strobe bit
  input    wire            i_space_wire_data_in,     // Input data bit
  // Output Flags
  output   wire    [08:00] o_rx_data_out,            // Received Data 
  output   wire            o_rx_data_valid_out,      // Received Data valid
  output   wire    [07:00] o_rx_time_code_out,       // Received Time Code 
  output   wire            o_rx_time_code_valid_out, // Received Time Code valid
  output   wire            o_rx_n_char_out,          // Received N-Chars
  output   wire            o_rx_fct_out,             // Received FCT
  output   wire            o_rx_null_out,            // Received NULL 
  output   wire            o_rx_eep_out,             // Received EEP
  output   wire            o_rx_eop_out,             // Received EOP
  output   wire            o_rx_off_out,             // Received OFF
  // Receiver Error - disconnect error or parity error or escape error
  output   wire            o_rx_error_out,           // Receiver Error
  // Out IP-core
  output   wire            o_parity_error_out,       // Parity Error
  output   wire            o_escape_error_out,       // Escape Error
  output   wire            o_disconnect_error_out,   // Disconnect Error
  // SpaceWire reset
  input    wire            i_space_wire_reset_n,     // SpaceWire reset
  // Write enable flag for RX fifo
  output   wire            o_rx_fifo_wren,           // Write enable
  // Receiver Enable
  input    wire            i_rx_en,                  // Receiver eneble
  // Receiver Clock
  input    wire            i_rx_clk                  // Receiver clock
);
  //----------------------------------------------------------------------------
  //  Constants
  //----------------------------------------------------------------------------
  // TYPE SpaceWire StateMachine:
  localparam SM_IDLE        = 0;
  localparam SM_OFF         = 1;
  localparam SM_EVEN0       = 2;
  localparam SM_EVEN1       = 3;
  localparam SM_WAIT_EVEN   = 4;
  localparam SM_ODD0        = 5;
  localparam SM_ODD1        = 6;
  localparam SM_WAIT_ODD    = 7;
  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------
  reg                parity_error_out;      // Output Parity Error bit
  reg                escape_error_out;      // Output Escape Error bit
  reg                rx_eop_out;            // Output receive EOP
  reg                rx_eep_out;            // Output receive EEP
  reg                rx_data_valid_out;     // Output receive Data valid flag
  reg     [08:00]    rx_data_out;           // Output receive Data
  reg     [07:00]    rx_time_code_out;      // Output receive time code
  reg                rx_time_code_valid_out;// Output receive time code valid
  reg                rx_fct_out;            // Output receive FCT
  reg                rx_null_out;           // Output receive NULL
  reg                rx_fifo_wren;          // Output write enable for RX fifo
  //
  reg                sw_data_in_z0;         // Double buffer 
  reg                sw_data_in_z1;         // for exclusion of metastability
  reg                sw_strobe_in_z0;       // Double buffer 
  reg                sw_strobe_in_z1;       // for exclusion of metastability
  //
  reg                space_wire_reset_n_z0; // Double buffer for
  reg                space_wire_reset_n_z1; // transfer to another clock domain
  //
  reg     [02:00]    state_space_wire;      // Detect a change of the DS signal
  reg     [07:00]    data_reg;              // Data shift register
  reg                parity;                // Internal Parity Error bit
  reg                esc_flag;              // Escape flag
  reg     [01:00]    space_wire_sync;       // Strobe and Data combination
  reg     [03:00]    bit_count;             // Counter for data decoding
  reg     [07:00]    link_time_out_counter; // Disconnect time counter
  reg                disconnect_error_out;  // Internal Disconnect Error bit
  reg                command_flag;          // Command receive flag
  reg                data_flag;             // Data receive flag
  reg                rx_en_z0;              // Double buffer for
  reg                rx_en_z1;              // transfer to another clock domain
  //----------------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------------
  wire               rx_n_char_out;
  wire               rx_off_out;
  wire               rx_error_out;
  //----------------------------------------------------------------------------
  assign o_rx_data_out              = rx_data_out;
  assign o_rx_time_code_out         = rx_time_code_out;
  assign o_rx_time_code_valid_out   = rx_time_code_valid_out;
  assign o_rx_n_char_out            = rx_n_char_out;
  assign o_rx_fct_out               = rx_fct_out;
  assign o_rx_null_out              = rx_null_out;
  assign o_rx_off_out               = rx_off_out;
  assign o_rx_error_out             = rx_error_out;
  assign o_rx_fifo_wren             = rx_fifo_wren;
  assign o_rx_data_valid_out        = rx_data_valid_out;
  assign o_rx_eop_out               = rx_eop_out;
  assign o_rx_eep_out               = rx_eep_out;
  assign o_parity_error_out         = parity_error_out;
  assign o_escape_error_out         = escape_error_out;
  assign o_disconnect_error_out     = disconnect_error_out;
  //----------------------------------------------------------------------------
  assign rx_off_out              = ( state_space_wire == SM_OFF ) ? 1'b1 : 1'b0;
  //----------------------------------------------------------------------------
  //disconnect error, parity error or escape error
  assign rx_error_out            = ( disconnect_error_out | 
                                     parity_error_out     | 
                                     escape_error_out     ) ? 1'b1 : 1'b0;
  //----------------------------------------------------------------------------
  assign rx_n_char_out           = ( rx_eop_out           | 
                                     rx_eep_out           | 
                                     rx_data_valid_out    ) ? 1'b1 : 1'b0;
  //----------------------------------------------------------------------------
  // Synchronize DS signal to the i_rx_clk.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_strobe_in
      // exclusion of metastability
      sw_data_in_z0         <= i_space_wire_data_in;
      sw_data_in_z1         <= sw_data_in_z0;
      sw_strobe_in_z0       <= i_space_wire_strobe_in;
      sw_strobe_in_z1       <= sw_strobe_in_z0;
      // combination
      space_wire_sync       <= {sw_strobe_in_z1, sw_data_in_z1};
    end //: s_strobe_in
  //----------------------------------------------------------------------------
  // Transfer input signal to another clock domain
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_transfer_input_to_rx_clk
      // exclusion of metastability and transfer to another clock domain
      space_wire_reset_n_z0   <= i_space_wire_reset_n;
      space_wire_reset_n_z1   <= space_wire_reset_n_z0;
      // exclusion of metastability and transfer to another clock domain
      rx_en_z0                <= i_rx_en;
      rx_en_z1                <= rx_en_z0;     
    end //: s_transfer_input_to_rx_clk
  //----------------------------------------------------------------------------
  // Detect a change of the DS signal.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk or negedge space_wire_reset_n_z1 or 
           posedge disconnect_error_out)
    begin : s_detect_ds
      if ( !space_wire_reset_n_z1 | disconnect_error_out )
        begin
          state_space_wire                  <= SM_IDLE;
        end
      else
        begin
         if ( rx_en_z1 )
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
    end //: s_detect_ds
  //----------------------------------------------------------------------------
  // Take the data into the shift register on the State transition 
  // of state_space_wire.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_data_shift_register
      if ( rx_en_z1 )
        begin
          if ( state_space_wire == SM_OFF )
            begin
              data_reg    <= 8'b00000000;
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
          data_reg        <= 8'b00000000;
        end
    end //: s_data_shift_register
  //----------------------------------------------------------------------------
  // ECSS-E-ST-50-12C 7.4 Parity for error detection.
  // Odd Parity.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_parity
      if ( rx_en_z1 & !escape_error_out & !disconnect_error_out )
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
    end //: s_parity
  //----------------------------------------------------------------------------
  // ECSS-E-ST-50-12C 8.5.3.7.2 Disconnect error.
  // Disconnect error is an error condition asserted
  // when the length of time since the last transition on
  // the D or S lines was longer than 850 ns nominal.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_disconnect
      if ( rx_en_z1 & !escape_error_out & !parity_error_out )
        begin
          if ( state_space_wire == SM_WAIT_ODD  | 
               state_space_wire == SM_WAIT_EVEN )
            begin
              // If i_rx_clk = 166MHz,
              // then T_rx_clk = 6ns,
              // if C_DISCONNECT_CNT_VAL = 141,
              // then 141*6 = 846ns
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
    end //: s_disconnect
  //----------------------------------------------------------------------------
  // ECSS-E-ST-50-12C 4.4 Character level
  // ECSS-E-ST-50-12C 7.2 Data characters
  // Discriminate the data character or the  the control character by the Data 
  // Control Flag.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_command_and_data_flag
      if ( rx_en_z1 )
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
    end //: s_command_and_data_flag
  //----------------------------------------------------------------------------
  // Increment bit of character corresponding by state transition of 
  // state_space_wire.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_bit_count_inc
      if ( rx_en_z1 & !escape_error_out & !disconnect_error_out )
        begin
          if ( state_space_wire == SM_IDLE | state_space_wire == SM_OFF)
            begin
              bit_count       <= 4'h0;
            end
          else if ( state_space_wire == SM_EVEN1 | state_space_wire == SM_EVEN0)
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
    end //: s_bit_count_inc
  //----------------------------------------------------------------------------
  // ECSS-E-ST-50-12C 7.3 Control characters and control codes.
  // Discriminate  Data character, Control code and Time corde, and write to 
  // Receive buffer
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_data_control_time_code
      if ( rx_en_z1 )
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
                      rx_fifo_wren        <= 1'b1;
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
                      rx_fifo_wren        <= 1'b1;
                    end
                end
            end
          else
            begin
              rx_fifo_wren                <= 1'b0;
            end
        end
    end //: s_data_control_time_code
  //----------------------------------------------------------------------------
  // ECSS-E-ST-50-12C 7.3 Control characters and control codes.
  // ECSS-E-ST-50-12C 8.5.3.7.4 Escape error.
  // Receive DataCharacter, ControlCode and TimeCode.
  //----------------------------------------------------------------------------
  always @(posedge i_rx_clk)
    begin : s_data_decode
      if ( rx_en_z1 & !disconnect_error_out & !parity_error_out )
        begin
          if ( bit_count == 0 & ( state_space_wire == SM_ODD0 | 
                                  state_space_wire == SM_ODD1 ) )
            begin
              if ( command_flag )
                begin
                  case ( data_reg[7:6] )
                    //----------------------------------------------------------
                    // ECSS-E-ST-50-12C 8.5.3.2 gotNULL.
                    // ECSS-E-ST-50-12C 8.5.3.3 gotFCT.
                    //----------------------------------------------------------
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
              //----------------------------------------------------------------
              // ECSS-E-ST-50-12C 8.5.3.5 gotTime-Code.
              // ECSS-E-ST-50-12C 8.5.3.4 gotN-Char.
              //----------------------------------------------------------------
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
          //--------------------------------------------------------------------
          // Clear the previous Receive flag before receiving data.
          //--------------------------------------------------------------------
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
    end //: s_data_decode
  //----------------------------------------------------------------------------
endmodule // module space_wire_rx

