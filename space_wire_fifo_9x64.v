//------------------------------------------------------------------------------
`timescale 1 ns / 1 ns // timescale for following modules
//------------------------------------------------------------------------------
module space_wire_fifo_9x64
(
  input    wire                 i_wr_clk,
  input    wire                 i_wren,
  input    wire    [8:0]        i_data,
  //---
  input    wire                 i_rd_clk,
  input    wire                 i_rden,
  output   wire    [8:0]        o_q,
  //---
  output   wire    [5:0]        o_wrusdw,
  output   wire    [5:0]        o_rdusdw,
  output   wire                 o_empty,
  output   wire                 o_full,
  //---
  input    wire                 i_reset
);
//------------------------------------------------------------------------------
reg     [8:0]        dpram [0:63];
localparam [5:0] binaryToGray = {6'b000000, 6'b000001, 6'b000011, 6'b000010, 6'b000110, 6'b000111, 6'b000101, 6'b000100, 6'b001100, 6'b001101, 6'b001111, 6'b001110, 6'b001010, 6'b001011, 6'b001001, 6'b001000, 6'b011000, 6'b011001, 6'b011011, 6'b011010, 6'b011110, 6'b011111, 6'b011101, 6'b011100, 6'b010100, 6'b010101, 6'b010111, 6'b010110, 6'b010010, 6'b010011, 6'b010001, 6'b010000, 6'b110000, 6'b110001, 6'b110011, 6'b110010, 6'b110110, 6'b110111, 6'b110101, 6'b110100, 6'b111100, 6'b111101, 6'b111111, 6'b111110, 6'b111010, 6'b111011, 6'b111001, 6'b111000, 6'b101000, 6'b101001, 6'b101011, 6'b101010, 6'b101110, 6'b101111, 6'b101101, 6'b101100, 6'b100100, 6'b100101, 6'b100111, 6'b100110, 6'b100010, 6'b100011, 6'b100001, 6'b100000}; 
localparam [5:0] grayToBinary = {6'b000000, 6'b000001, 6'b000011, 6'b000010, 6'b000111, 6'b000110, 6'b000100, 6'b000101, 6'b001111, 6'b001110, 6'b001100, 6'b001101, 6'b001000, 6'b001001, 6'b001011, 6'b001010, 6'b011111, 6'b011110, 6'b011100, 6'b011101, 6'b011000, 6'b011001, 6'b011011, 6'b011010, 6'b010000, 6'b010001, 6'b010011, 6'b010010, 6'b010111, 6'b010110, 6'b010100, 6'b010101, 6'b111111, 6'b111110, 6'b111100, 6'b111101, 6'b111000, 6'b111001, 6'b111011, 6'b111010, 6'b110000, 6'b110001, 6'b110011, 6'b110010, 6'b110111, 6'b110110, 6'b110100, 6'b110101, 6'b100000, 6'b100001, 6'b100011, 6'b100010, 6'b100111, 6'b100110, 6'b100100, 6'b100101, 6'b101111, 6'b101110, 6'b101100, 6'b101101, 6'b101000, 6'b101001, 6'b101011, 6'b101010}; 
reg                  wr_reset; 
reg                  rd_reset; 
reg     [1:0]        wr_reset_time; 
reg     [1:0]        rd_reset_time; 
reg     [5:0]        wr_pointer; 
reg     [5:0]        gray_wr_pointer; 
reg     [5:0]        gray_wr_pointer1; 
reg     [5:0]        gray_wr_pointer2; 
reg     [5:0]        gray_wr_pointer3; 
reg     [5:0]        wr_pointer4; 
reg     [5:0]        rd_pointer; 
reg     [5:0]        gray_rd_pointer; 
reg     [5:0]        gray_rd_pointer1; 
reg     [5:0]        gray_rd_pointer2; 
reg     [5:0]        rd_pointer3; 
wire    [5:0]        wrusdw; 
wire                 full; 
reg     [8:0]        q; 
wire    [5:0]        rdusdw; 
wire                 empty; 
//------------------------------------------------------------------------------
assign  o_wrusdw     = wrusdw; 
assign  o_full       = full; 
assign  o_empty      = empty; 
assign  o_rdusdw     = rdusdw; 
assign  o_q          = q; 
//------------------------------------------------------------------------------
assign wrusdw = wr_pointer - rd_pointer3;
assign full = wr_pointer - rd_pointer3 > 6'b111000 | wr_reset == 1'b1 ? 1'b1 : 1'b0; 
assign rdusdw = wr_pointer4 - rd_pointer; 
assign empty = wr_pointer4 == rd_pointer | rd_reset == 1'b1 ? 1'b1 : 1'b0; 
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// synchronized i_reset to i_wr_clk.
//==============================================================================
always @(posedge i_reset or posedge i_wr_clk)
  begin : s_sync_wr_reset
  if ( i_reset )
    begin
      wr_reset_time  <= 2'b11;
      wr_reset       <= 1'b1;
    end
  else
    begin
      wr_reset_time  <= { wr_reset_time[0], i_reset };
      wr_reset       <= wr_reset_time[1];
    end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Write pointer of the buffer.
//==============================================================================
always @(posedge i_wr_clk)
  begin : s_wr_pointer
  if ( wr_reset )
    begin
      wr_pointer  <= 6'b000000;
    end
  else if ( i_wren )
    begin
      wr_pointer  <= wr_pointer + 1'b1;
    end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Writing to buffer.
//==============================================================================
always @(posedge i_wr_clk)
  begin : s_wr_data
    if ( i_wren )
      begin
        dpram[ wr_pointer ]  <= i_data;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Change to Gray code.
//==============================================================================
always @(posedge i_wr_clk)
  begin : s_wr_binary_to_gray
    if ( wr_reset )
      begin
        gray_wr_pointer  <= 6'b000000;
      end
    else
      begin
        //gray_wr_pointer <= binaryToGray[ wr_pointer ];
        gray_wr_pointer  <= wr_pointer;
      end
   end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Convert gray code Readpointer to binary Readpointer to calculate o_wrusdw 
// and o_full.
//==============================================================================
always @(posedge i_wr_clk)
  begin : s_gray_rd_pointer_z
    if ( wr_reset )
      begin
        gray_rd_pointer1  <= 6'b000000;
        gray_rd_pointer2  <= 6'b000000;
        rd_pointer3       <= 6'b000000;
      end
    else
      begin
        gray_rd_pointer1  <= gray_rd_pointer;
        gray_rd_pointer2  <= gray_rd_pointer1;
        //rd_pointer3     <= grayToBinary[ gray_rd_pointer2 ];
        rd_pointer3       <= gray_rd_pointer2;
      end
    end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Convert gray code Writepointer to binary Writepointer to calculate o_rdusdw 
// and o_empty.
//==============================================================================
always @(posedge i_rd_clk)
  begin : s_gray_wr_pointer
    if ( rd_reset )
      begin
        gray_wr_pointer1  <= 6'b000000;
        gray_wr_pointer2  <= 6'b000000;
        gray_wr_pointer3  <= 6'b000000;
        wr_pointer4       <= 6'b000000;
      end
    else
      begin
        gray_wr_pointer1  <= gray_wr_pointer;
        gray_wr_pointer2  <= gray_wr_pointer1;
        gray_wr_pointer3  <= gray_wr_pointer2;
        //wr_pointer4     <= grayToBinary[gray_wr_pointer3];
        wr_pointer4       <= gray_wr_pointer3;
      end
    end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Read from buffer.
//==============================================================================
always @(posedge i_rd_clk)
  begin : s_q
    if ( !empty )
      begin
      if ( i_rden )
        begin
          q  <= dpram[ rd_pointer ];
        end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Read pointer of the buffer.
//==============================================================================
always @(posedge i_rd_clk)
  begin : s_rd_pointer
    if ( rd_reset )
      begin
        rd_pointer <= 6'b000000;
      end
    else if ( !empty )
      begin
        if ( i_rden )
          begin
            rd_pointer <= rd_pointer + 1'b1;
          end
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// Change to Gray code.
//==============================================================================
always @(posedge i_rd_clk)
  begin : s_rd_binary_to_gray
    if ( rd_reset )
      begin
        gray_rd_pointer  <= 6'b000000;
      end
    else
      begin
        //gray_rd_pointer <= binaryToGray[ rd_pointer ];
        gray_rd_pointer  <= rd_pointer;
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
//==============================================================================
// synchronized i_reset to i_rd_clk.
//==============================================================================
always @(posedge i_reset or posedge i_rd_clk)
  begin : s_sync_rd_reset
    if ( i_reset )
      begin
        rd_reset_time  <= 2'b11;
        rd_reset       <= 1'b1;
      end
    else
      begin
        rd_reset_time  <= { rd_reset_time[0], i_reset };
        rd_reset       <= rd_reset_time[1];
      end
  end
//------------------------------------------------------------------------------
//---
//---
//---
endmodule // module space_wire_fifo_9x64

