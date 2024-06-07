module trade_decision_tb ();
    logic [177:0] message_i;
    logic [63:0] average_i;
    logic clk_i, reset_i, v_i, yumi_i, ready_o, v_o;
    logic [177:0] trade_o;
    trade_decision dut (.*);

    // Set up the clock
    parameter CLOCK_PERIOD=1000000;
    initial begin
        clk_i <= 0;
        forever #(CLOCK_PERIOD/2) clk_i <= ~clk_i;
    end

    initial begin
        $fsdbDumpfile("waveform.fsdb");
         $fsdbDumpvars();
        @(posedge clk_i);
        reset_i <= 1'b1;
        @(posedge clk_i);
        average_i <= 64'b0000000000000000000000000000000000000000000000000010011100010000; // average_i of 100
        message_i <= 178'b0100100011011101011011101011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100111001010010000000000000000000000000000000010100000;
        reset_i <= 1'b0;
        v_i <= 1'b1;
        @(posedge clk_i);
        v_i <= 1'b0;
        @(posedge clk_i);
        yumi_i <= 1'b1;
        
        $display("message_i %b", message_i);
        $display("trade_o %b", trade_o);
        @(posedge clk_i);
        yumi_i <= 1'b0;
        message_i <= 178'b1000100011011101011011101011011000_0000000000000000000000000000000000000000000000000000000000001100_01010000_000000000000000000000000000000000000000000000000000000000000000000000000;
        v_i <= 1'b1;
        @(posedge clk_i);
        @(posedge clk_i);
        yumi_i <=1;
        @(posedge clk_i);
        @(posedge clk_i);
        
        $display("message_i %b", message_i);
        $display("trade_o %b", trade_o);
        @(posedge clk_i);
        //$stop; //end simulation
        $finish;
    end

endmodule
