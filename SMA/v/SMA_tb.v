module SMA_tb(logic [63:0] new_data
             ,logic [63:0] average
             ,logic clk
             );

    SMA dut(*);

    // Set up the clock
   parameter CLOCK_PERIOD=100;
   initial begin
	 clk <= 0;
	 forever #(CLOCK_PERIOD/2) clk <= ~clk;
   end



    initial begin
    new_data <= 0000000000000000000000000000000000000000000000000000000000000011; #10 //Value:3  , Average: 3
    $display("average =%d" , average);
    new_data <= 0000000000000000000000000000000000000000000000000000000000001111; #10 //Value:15 , Average: 9
    $display("average =%d" , average);
    new_data <= 0000000000000000000000000000000000000000000000000000000000010111; #10 //Value:23 , Average: 13.67
    $display("average =%d" , average);
    new_data <= 0000000000000000000000000000000000000000000000000000000001101001; #10 //Value:105, Average: 36.5
    $display("average =%d" , average);
    new_data <= 0000000000000000000000000000000000000000000000000000000001101001; #10 //Value:105, Average: 50.2
    $display("average =%d" , average);
    new_data <= 0000000000000000000000000000000000000000000000000000000001101001; #10 //Value:105, Average: 59.33
    $display("average =%d" , average);
    new_data <= 0000000000000000000000000000000000000000000000000000000001000001; #10 //Value:65 , Average: 60.14
    $display("average =%d" , average);


    end
endmodule