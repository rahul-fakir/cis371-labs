/* Nickhil Nabar, Sahil Ahuja, Nikhil Raman
 * TODO: pennkey of all group members
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 * TODO: nnabar, ramann, sahilahu
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module Nbit_mux8to1 #(parameter n = 16)
   (input  wire [  2:0] sel,
    input  wire [n-1:0] a,
    input  wire [n-1:0] b,
    input  wire [n-1:0] c,
    input  wire [n-1:0] d,
    input  wire [n-1:0] e,
    input  wire [n-1:0] f,
    input  wire [n-1:0] g,
    input  wire [n-1:0] h,
    output wire [n-1:0] out
    );
    
    assign out = (sel == 3'd0) ? a :
                 (sel == 3'd1) ? b :
                 (sel == 3'd2) ? c :
                 (sel == 3'd3) ? d :
                 (sel == 3'd4) ? e :
                 (sel == 3'd5) ? f :
                 (sel == 3'd6) ? g: h;
    
endmodule

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

    wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;
    
    Nbit_reg #(n) r0 (i_wdata, r0v, clk, (i_rd == 3'd0) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r1 (i_wdata, r1v, clk, (i_rd == 3'd1) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r2 (i_wdata, r2v, clk, (i_rd == 3'd2) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r3 (i_wdata, r3v, clk, (i_rd == 3'd3) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r4 (i_wdata, r4v, clk, (i_rd == 3'd4) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r5 (i_wdata, r5v, clk, (i_rd == 3'd5) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r6 (i_wdata, r6v, clk, (i_rd == 3'd6) & i_rd_we, gwe, rst);
    Nbit_reg #(n) r7 (i_wdata, r7v, clk, (i_rd == 3'd7) & i_rd_we, gwe, rst);
    Nbit_mux8to1 #(n) mux1 (i_rs, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rs_data);
    Nbit_mux8to1 #(n) mux2 (i_rt, r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v, o_rt_data);

endmodule