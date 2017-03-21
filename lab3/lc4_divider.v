/* Nickhil Nabar, nnabar, 72435097 */

`timescale 1ns / 1ps

/* Prevent implicit wire declaration
 *
 * This directive will cause Vivado to give an error if you
 * haven't declared a wire (including if you have a typo.
 * 
 * The price you pay for this is that you have to write
 * "input wire" and "output wire" for all your ports
 * instead of just "input" and "output".
 * 
 * All the provided infrastructure code has been updated.
 */
`default_nettype none

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient, 
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);
   
   wire [15:0] new_remainder = {i_remainder[14:0], i_dividend[15]};
   wire [15:0] if_quotient = {i_quotient[14:0], 1'd0};
   wire [15:0] else_quotient = {i_quotient[14:0], 1'd1};
   wire [15:0] else_remainder = new_remainder - i_divisor;
   
   assign o_quotient = (new_remainder < i_divisor) ? if_quotient : else_quotient;
   assign o_remainder = (new_remainder < i_divisor) ? new_remainder : else_remainder;
   assign o_dividend = {i_dividend[14:0], 1'd0};
   
endmodule

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);
                   
    wire [15:0] dividend_1;
    wire [15:0] remainder_1;
    wire [15:0] quotient_1;
    wire [15:0] dividend_2;
    wire [15:0] remainder_2;
    wire [15:0] quotient_2;
    wire [15:0] dividend_3;
    wire [15:0] remainder_3;
    wire [15:0] quotient_3;
    wire [15:0] dividend_4;
    wire [15:0] remainder_4;
    wire [15:0] quotient_4;
    wire [15:0] dividend_5;
    wire [15:0] remainder_5;
    wire [15:0] quotient_5;
    wire [15:0] dividend_6;
    wire [15:0] remainder_6;
    wire [15:0] quotient_6;
    wire [15:0] dividend_7;
    wire [15:0] remainder_7;
    wire [15:0] quotient_7;
    wire [15:0] dividend_8;
    wire [15:0] remainder_8;
    wire [15:0] quotient_8;
    wire [15:0] dividend_9;
    wire [15:0] remainder_9;
    wire [15:0] quotient_9;
    wire [15:0] dividend_10;
    wire [15:0] remainder_10;
    wire [15:0] quotient_10;
    wire [15:0] dividend_11;
    wire [15:0] remainder_11;
    wire [15:0] quotient_11;
    wire [15:0] dividend_12;
    wire [15:0] remainder_12;
    wire [15:0] quotient_12;
    wire [15:0] dividend_13;
    wire [15:0] remainder_13;
    wire [15:0] quotient_13;
    wire [15:0] dividend_14;
    wire [15:0] remainder_14;
    wire [15:0] quotient_14;
    wire [15:0] dividend_15;
    wire [15:0] remainder_15;
    wire [15:0] quotient_15;
    wire [15:0] dividend_16;
    wire [15:0] remainder_16;
    wire [15:0] quotient_16;
    
    lc4_divider_one_iter iter_1(.i_dividend(i_dividend), .i_divisor(i_divisor), .i_remainder(16'd0), .i_quotient(16'd0), .o_dividend(dividend_1), .o_remainder(remainder_1), .o_quotient(quotient_1));
    lc4_divider_one_iter iter_2(.i_dividend(dividend_1), .i_divisor(i_divisor), .i_remainder(remainder_1), .i_quotient(quotient_1), .o_dividend(dividend_2), .o_remainder(remainder_2), .o_quotient(quotient_2));
    lc4_divider_one_iter iter_3(.i_dividend(dividend_2), .i_divisor(i_divisor), .i_remainder(remainder_2), .i_quotient(quotient_2), .o_dividend(dividend_3), .o_remainder(remainder_3), .o_quotient(quotient_3));
    lc4_divider_one_iter iter_4(.i_dividend(dividend_3), .i_divisor(i_divisor), .i_remainder(remainder_3), .i_quotient(quotient_3), .o_dividend(dividend_4), .o_remainder(remainder_4), .o_quotient(quotient_4));
    lc4_divider_one_iter iter_5(.i_dividend(dividend_4), .i_divisor(i_divisor), .i_remainder(remainder_4), .i_quotient(quotient_4), .o_dividend(dividend_5), .o_remainder(remainder_5), .o_quotient(quotient_5));
    lc4_divider_one_iter iter_6(.i_dividend(dividend_5), .i_divisor(i_divisor), .i_remainder(remainder_5), .i_quotient(quotient_5), .o_dividend(dividend_6), .o_remainder(remainder_6), .o_quotient(quotient_6));
    lc4_divider_one_iter iter_7(.i_dividend(dividend_6), .i_divisor(i_divisor), .i_remainder(remainder_6), .i_quotient(quotient_6), .o_dividend(dividend_7), .o_remainder(remainder_7), .o_quotient(quotient_7));
    lc4_divider_one_iter iter_8(.i_dividend(dividend_7), .i_divisor(i_divisor), .i_remainder(remainder_7), .i_quotient(quotient_7), .o_dividend(dividend_8), .o_remainder(remainder_8), .o_quotient(quotient_8));
    lc4_divider_one_iter iter_9(.i_dividend(dividend_8), .i_divisor(i_divisor), .i_remainder(remainder_8), .i_quotient(quotient_8), .o_dividend(dividend_9), .o_remainder(remainder_9), .o_quotient(quotient_9));
    lc4_divider_one_iter iter_10(.i_dividend(dividend_9), .i_divisor(i_divisor), .i_remainder(remainder_9), .i_quotient(quotient_9), .o_dividend(dividend_10), .o_remainder(remainder_10), .o_quotient(quotient_10));
    lc4_divider_one_iter iter_11(.i_dividend(dividend_10), .i_divisor(i_divisor), .i_remainder(remainder_10), .i_quotient(quotient_10), .o_dividend(dividend_11), .o_remainder(remainder_11), .o_quotient(quotient_11));
    lc4_divider_one_iter iter_12(.i_dividend(dividend_11), .i_divisor(i_divisor), .i_remainder(remainder_11), .i_quotient(quotient_11), .o_dividend(dividend_12), .o_remainder(remainder_12), .o_quotient(quotient_12));
    lc4_divider_one_iter iter_13(.i_dividend(dividend_12), .i_divisor(i_divisor), .i_remainder(remainder_12), .i_quotient(quotient_12), .o_dividend(dividend_13), .o_remainder(remainder_13), .o_quotient(quotient_13));
    lc4_divider_one_iter iter_14(.i_dividend(dividend_13), .i_divisor(i_divisor), .i_remainder(remainder_13), .i_quotient(quotient_13), .o_dividend(dividend_14), .o_remainder(remainder_14), .o_quotient(quotient_14));
    lc4_divider_one_iter iter_15(.i_dividend(dividend_14), .i_divisor(i_divisor), .i_remainder(remainder_14), .i_quotient(quotient_14), .o_dividend(dividend_15), .o_remainder(remainder_15), .o_quotient(quotient_15));
    lc4_divider_one_iter iter_16(.i_dividend(dividend_15), .i_divisor(i_divisor), .i_remainder(remainder_15), .i_quotient(quotient_15), .o_dividend(dividend_16), .o_remainder(remainder_16), .o_quotient(quotient_16));
    
    assign o_remainder = (i_divisor == 0) ? 16'd0 : remainder_16;
    assign o_quotient = (i_divisor == 0) ? 16'd0 : quotient_16;

endmodule