module D_FF_32b (dataOut, dataIn, reset, clk);
    output [31:0] dataOut;
    input [31:0] dataIn;
    input reset, clk;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin: d_ff_32
            D_FF dff (.q(dataOut[i]), .d(dataIn[i]), .reset(reset), .clk(clk));
        end
    endgenerate
endmodule
