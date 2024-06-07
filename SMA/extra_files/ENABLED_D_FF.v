module enabled_D_FF #(parameter WIDTH) (dataIn, dataOut, reset, clk, enable);
    output [WIDTH-1:0] dataOut;
    input [WIDTH-1:0] dataIn;
    input reset, clk, enable;

    logic [WIDTH-1:0] temp_out;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin: d_ff_custom
            MUX2_1 mux2x1 (.out(temp_out[i]), .data_0(dataOut[i]), .data_1(dataIn[i]), .select(enable));
            D_FF dff (.q(dataOut[i]), .d(temp_out[i]), .reset(reset), .clk(clk));
        end
    endgenerate
endmodule
