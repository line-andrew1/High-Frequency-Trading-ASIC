module SMA (reset_i, clk_i, data_i, data_o);
    input logic reset_i, clk_i;
    input logic [63:0] data_i;
    output logic [63:0] data_o;

    logic [3:0][63:0] reg_data;
    logic [255:0] sum;
    logic [63:0] average;

    always_comb begin
        if (reset_i) begin
            sum <= 0;
            average <=0;
            for (i=0; i<4, i++) begin
                reg_data[i] <= 0;
                $display("data %d", reg_data[i]);
            end
        end
    end
endmodule