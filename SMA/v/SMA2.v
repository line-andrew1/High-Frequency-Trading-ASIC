
/*
    Project Title: Implementation of a High-Frequency ASIC System
    Authors: Andrew Line, Benito Elmer
    Date: May 2024
    https://github.com/line-andrew1/High-Frequency-Trading-ASIC
 
    **** Simple Moving Average Module ****

    Objective: Perform averaging calcuations on incoming data over a set window.

    Parameters:
           WINDOW_SIZE: Sets the size of the averaging window.
                Note: adjustments will need to be made for a window greater than 4.
           DATA_WIDTH: Sets bit size of incoming data. Works best in power2.
    Input: 
           1b'x           clk_i
           1b'x           reset_i
           DATA_WIDTH_b'x data_i
    Output:
           DATA_WIDTH_b'x average_o
*/



module SMA2 #(
    parameter WINDOW_SIZE = 4,
    parameter DATA_WIDTH = 64
)(
    input clk_i,
    input reset_i,
    input [DATA_WIDTH-1:0] data_i,
    output [DATA_WIDTH-1:0] average_o
);

    reg  [DATA_WIDTH*WINDOW_SIZE - 1:0] values;
    reg [DATA_WIDTH-1:0] data_r;
    wire [DATA_WIDTH*WINDOW_SIZE - 1:0]  sum_r;
    wire [63:0] data1;
    wire [63:0] data2;
    wire [63:0] data3;
    wire [63:0] data4;
    reg [2:0] i_r;
 

    //Store values in a flip flop
    always @(posedge clk_i) begin
	 if(reset_i) begin
        data_r <= 0;
		  end
		  else begin
        data_r <= data_i;
		  end
		  
    end

    //Reset block
    always @(negedge clk_i) begin
        if(reset_i) begin
            i_r <= 0;
            values <= 0;

        end else begin

            // Change value
            values <= {values[191:0],data_r};

            // Changing the indexes
            if (i_r == 4) begin
                i_r <= 4;
            end else begin
                i_r <= i_r + 1'b1;
            end
        end
    end

    //Assign value literal back to individual data blocks
    assign data1 = values[63:0] ;
    assign data2 = values[127:64] ;
    assign data3 = values[191:128] ;
    assign data4 = values[255:192] ;

	 // Calculate Average
     assign       average_o = sum_r / (i_r);

    // Add new value to sum
	 assign 	sum_r = data1   + data2   + data3   + data4;	
	 
endmodule



