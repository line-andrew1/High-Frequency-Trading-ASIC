module MUX2_1 (out, data_0, data_1, select);
    output logic out;
    input logic data_0, data_1, select;

    logic inv_select, temp_0, temp_1;

    not #0.05 not1 (inv_select, select);

    and #0.05 and1 (temp_0, data_0, inv_select);
    and #0.05 and2 (temp_1, data_1, select);
    or #0.05 or1 (out, temp_1, temp_0);

endmodule