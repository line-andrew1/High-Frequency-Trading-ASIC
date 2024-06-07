/*
    Project Title: Implementation of a High-Frequency ASIC System
    Authors: Andrew Line, Benito Elmer
    Date: May 2024
    https://github.com/line-andrew1/High-Frequency-Trading-ASIC

    This is the main module for making decisions to trade based on the preset thresholds of +/- 5
    It takes the inputs of a average and a message that is created according to the readme of this file
    in serial. It outputs a trade out decision in the same format.
*/
module trade_decision (
    input logic [177:0] message_i,
    input logic [63:0] average_i,
    input logic clk_i, reset_i, v_i, yumi_i,
    output logic ready_o, v_o,
    output logic [177:0] trade_o 
);

logic [127:0] total_price, total_price_r; // Total Price for all securities bought
logic [7:0] total_purchased, total_purchased_r; // Total number of securities bought

logic [63:0] scaled_average_buy, scaled_average_sell;

// Control Signals
logic buy_sell, buy_sell_r; // Indicates a trade is to be made
logic [177:0] trade_make, trade_make_r;

// Split Encoded Signals
logic [1:0] MsgType, MsgType_r;
logic [31:0] Symbol, Symbol_r;
logic [63:0] BidPx, BidPx_r;
logic [7:0] BidSize, BidSize_r;
logic [63:0] OfferPx, OfferPx_r;
logic [7:0] OfferSize, OfferSize_r;

// Next State Logic
typedef enum logic [1:0] {WAIT, BUSY, DONE} state;
state current_state, next_state;

// Handshake Signal Handling
assign ready_o = (current_state == WAIT);
assign v_o = (current_state == DONE);

// Threshold Calculation
assign scaled_average_buy = average_i - 5; 
assign scaled_average_sell = average_i + 5; 

// State Transition Logic
always_comb begin
    next_state = current_state;
    buy_sell = 1'b0;
    trade_make = 0;
    total_price = total_price_r;
    total_purchased = total_purchased_r;

    case(current_state) 
        WAIT: begin
            if (v_i) begin
                next_state = BUSY;
            end
        end
        BUSY: begin
            if ((MsgType_r == 2'b01) & (OfferPx_r > scaled_average_sell) & (total_purchased_r != 0)) begin // SELL
                if (total_purchased_r < OfferSize_r) begin
                    trade_make = {2'b10, Symbol_r, OfferPx_r, total_purchased_r, 72'b0};
                end else begin
                    trade_make = {2'b10, Symbol_r, OfferPx_r, OfferSize_r, 72'b0};
                end
                buy_sell = 1'b1;
            end else if ((MsgType_r == 2'b10) & (BidPx_r < scaled_average_buy)) begin // BUY
                trade_make = {2'b01, Symbol_r, 72'b0, BidPx_r, BidSize_r};
                buy_sell = 1'b1;
            end else if (MsgType_r == 2'b11) begin // CONFIRM
                if (BidSize_r != 0) begin
                    total_price = total_price_r - ((total_price_r / total_purchased_r) * BidSize_r);
                    total_purchased = total_purchased_r - BidSize_r; 
                end
                if (OfferSize_r != 0) begin
                    total_price = total_price_r + (OfferPx_r * OfferSize_r);
                    total_purchased = total_purchased_r + OfferSize_r;
                end
                trade_make = 178'b0;
            end else begin
                trade_make = 178'b0;
            end
            next_state = DONE;
        end
        DONE: begin
            if (v_o & yumi_i) begin
                next_state = WAIT;
            end
        end
    endcase
end

// Register Updates
always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
        current_state <= WAIT;
        MsgType_r <= 0;
        Symbol_r <= 0;
        BidPx_r <= 0;
        BidSize_r <= 0;
        OfferPx_r <= 0;
        OfferSize_r <= 0;
        buy_sell_r <= 0;
        trade_make_r <= 0;
        total_price_r <= 0;
        total_purchased_r <= 0;
    end else begin
        current_state <= next_state;
        if (current_state == WAIT && v_i) begin
            MsgType_r <= message_i[177:176];
            Symbol_r <= message_i[175:144];
            BidPx_r <= message_i[143:80];
            BidSize_r <= message_i[79:72];
            OfferPx_r <= message_i[71:8];
            OfferSize_r <= message_i[7:0];
        end else begin
            MsgType_r <= MsgType;
            Symbol_r <= Symbol;
            BidPx_r <= BidPx;
            BidSize_r <= BidSize;
            OfferPx_r <= OfferPx;
            OfferSize_r <= OfferSize;
        end
        buy_sell_r <= buy_sell;
        trade_make_r <= trade_make;
        total_price_r <= total_price;
        total_purchased_r <= total_purchased;
    end
end

assign trade_o = trade_make_r;

endmodule
