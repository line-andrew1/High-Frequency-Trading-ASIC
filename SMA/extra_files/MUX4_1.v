module MUX4_1 (out, dataIn0, dataIn1, dataIn2, dataIn3, select);
    output logic out;
    input logic dataIn0, dataIn1, dataIn2, dataIn3;
    input logic [1:0] select;

    logic temp_0, temp_1;

    MUX2_1 MUX0 (.out(temp_0), .data_0(dataIn0), .data_1(dataIn1), .select(select[0]));
    MUX2_1 MUX1 (.out(temp_1), .data_0(dataIn2), .data_1(dataIn3), .select(select[0]));
    MUX2_1 MUX2 (.out(out), .data_0(temp_0), .data_1(temp_1), .select(select[1]));

endmodule
