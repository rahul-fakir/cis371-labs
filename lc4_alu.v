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

module branch(input  wire [15:0] i_insn,
               input  wire [15:0] i_pc,
               input  wire [15:0] i_r1data,
               input  wire [15:0] i_r2data,
               output wire [15:0] o_result);

    wire [15:0] sext_IMM9 = {{8{i_insn[8]}}, i_insn[7:0]};
   
    assign o_result = i_pc + sext_IMM9 + 1;

endmodule

module arith(input  wire [15:0] i_insn,
             input  wire [15:0] i_pc,
             input  wire [15:0] i_r1data,
             input  wire [15:0] i_r2data,
             output wire [15:0] o_result);
   
    wire imm_select;
    wire [1:0] op_select;
   
    wire [15:0] sext_IMM5;
    wire [15:0] imm_result, add_result, mult_result, sub_result, div_result, remainder;
   
    assign imm_select = i_insn[5];
    assign op_select = i_insn[4:3];
                     
    assign sext_IMM5 = {{12{i_insn[4]}}, i_insn[3:0]};
    assign imm_result = i_r1data + sext_IMM5;
    assign add_result = i_r1data + i_r2data;
    assign mult_result = i_r1data * i_r2data;
    assign sub_result = i_r1data - i_r2data;
    lc4_divider divider(i_r1data, i_r2data, remainder, div_result);

    assign o_result = imm_select ? imm_result : 
                      (op_select == 2'd0) ? add_result :
                      (op_select == 2'd1) ? mult_result :
                      (op_select == 2'd2) ? sub_result : div_result;

endmodule

module compare(input  wire [15:0] i_insn,
               input  wire [15:0] i_pc,
               input  wire [15:0] i_r1data,
               input  wire [15:0] i_r2data,
               output wire [15:0] o_result);
   
    /*wire [1:0] select;
    wire [16:0] sext_r1, sext_r2, diff, sext_IMM7, diff_sext_IMM7;
    wire [15:0] cmp_result, cmpu_result, cmpi_result, cmpiu_result, diff_IMM7;
    
    assign select = i_insn[8:7];
    
    assign sext_r1 = {i_r1data[15], i_r1data};
    assign sext_r2 = {i_r2data[15], i_r2data};
    assign diff = sext_r1 - sext_r2;
    assign cmp_result = (i_r1data == i_r2data) ? 16'd0 :
                        (diff[16] == 1'd0) ? 16'd1 : 16'hFFFF;
                        
    assign cmpu_result = (i_r1data == i_r2data) ? 16'd0 :
                         (i_r1data > i_r2data) ? 16'd1 : 16'hFFFF;
                         
    assign sext_IMM7 = {{11{i_insn[6]}}, i_insn[5:0]};
    assign diff_sext_IMM7 = sext_r1 - sext_IMM7;
    assign cmpi_result = (diff_sext_IMM7 == 1'd0) ? 16'd0 :
                         (diff_sext_IMM7[16] == 1'd0) ? 16'd1 : 16'hFFFF;
    
    assign diff_IMM7 = i_r1data - i_insn[6:0];                     
    assign cmpiu_result = (diff_IMM7 == 1'd0) ? 16'd0 :
                         (diff_IMM7 > 0) ? 16'd1 : 16'hFFFF;
    
    assign o_result = (select == 2'd0) ? cmp_result :
               (select == 2'd1) ? cmpu_result :
               (select == 2'd2) ? cmpi_result : cmpiu_result; */

   /* Calculate comparison operations */ 
   wire [15:0] cmp_mux_result; 
   wire [16:0] cmp_result, cmpu_result, cmpi_result, cmpiu_result, cmp_inter_result; 
   wire [16:0] sext_r1data, sext_r2data, uext_r1data, uext_r2data, sext17_imm7, uext_imm7;
   wire [1:0] cmp_sub_opcode = i_insn[8:7]; 
   assign sext_r1data = (i_r1data[15] == 0) ? {1'b0, i_r1data[15:0]} : {1'b1, i_r1data[15:0]}; 
   assign sext_r2data = (i_r2data[15] == 0) ? {1'b0, i_r2data[15:0]} : {1'b1, i_r2data[15:0]};
   assign uext_r1data = {1'b0, i_r1data[15:0]};
   assign uext_r2data = {1'b0, i_r2data[15:0]}; 
   assign sext17_imm7 = (i_insn[6] == 0) ? ({10'd0, i_insn[6:0]}) : ({10'h3FF, i_insn[6:0]}); 
   assign uext_imm7 = {10'd0, i_insn[6:0]}; 
   // extended inputs above, make calculations below
   assign cmp_result = sext_r1data - sext_r2data; 
   assign cmpu_result = uext_r1data - uext_r2data; 
   assign cmpi_result = sext_r1data - sext17_imm7; 
   assign cmpiu_result = uext_r1data - uext_imm7; 
   // pick which one we actually want 
   assign cmp_inter_result = (cmp_sub_opcode == 2'b00) ? cmp_result : 
                             (cmp_sub_opcode == 2'b01) ? cmpu_result :
                             (cmp_sub_opcode == 2'b10) ? cmpi_result : cmpiu_result;  
   assign cmp_mux_result = (cmp_inter_result == 17'd0) ? 16'd0 : 
                           (cmp_inter_result[16] == 1) ? 16'hFFFF : 16'd1;  
                           
   assign o_result = cmp_mux_result; 

endmodule

module jsrs(input  wire [15:0] i_insn,
           input  wire [15:0] i_pc,
           input  wire [15:0] i_r1data,
           input  wire [15:0] i_r2data,
           output wire [15:0] o_result);
    
    wire select;
    wire [15:0] shifted_IMM11;
    wire [15:0] pc_inter, jsr_result;
    
    assign select = i_insn[11];
    
    assign pc_inter = i_pc & 16'h8000;
    assign shifted_IMM11 = {1'd0, i_insn[10:0], 4'd0};
    assign jsr_result = pc_inter | shifted_IMM11;
    
    assign o_result = (select == 1'd1) ? jsr_result : i_r1data;

endmodule

module bool_logic(input  wire [15:0] i_insn,
                  input  wire [15:0] i_pc,
                  input  wire [15:0] i_r1data,
                  input  wire [15:0] i_r2data,
                  output wire [15:0] o_result);
   
    wire imm_select;
    wire [1:0] op_select;
   
    wire [15:0] sext_IMM5;
    wire [15:0] imm_result, and_result, not_result, or_result, xor_result;
   
    assign imm_select = i_insn[5];
    assign op_select = i_insn[4:3];
                     
    assign sext_IMM5 = {{12{i_insn[4]}}, i_insn[3:0]};
    assign imm_result = i_r1data & sext_IMM5;
    assign and_result = i_r1data & i_r2data;
    assign not_result = ~i_r1data;
    assign or_result = i_r1data | i_r2data;
    assign xor_result = i_r1data ^ i_r2data;

    assign o_result = imm_select ? imm_result : 
                      (op_select == 2'd0) ? and_result :
                      (op_select == 2'd1) ? not_result :
                      (op_select == 2'd2) ? or_result : xor_result;

endmodule

module mem(input  wire [15:0] i_insn,
           input  wire [15:0] i_pc,
           input  wire [15:0] i_r1data,
           input  wire [15:0] i_r2data,
           output wire [15:0] o_result);
    
    wire [15:0] sext_IMM6;
   
    assign sext_IMM6 = {{11{i_insn[5]}}, i_insn[4:0]};
    assign o_result = i_r1data + sext_IMM6;

endmodule

module rti(input  wire [15:0] i_insn,
           input  wire [15:0] i_pc,
           input  wire [15:0] i_r1data,
           input  wire [15:0] i_r2data,
           output wire [15:0] o_result);
    
    assign o_result = i_r1data;

endmodule

module lc4_const(input  wire [15:0] i_insn,
             input  wire [15:0] i_pc,
             input  wire [15:0] i_r1data,
             input  wire [15:0] i_r2data,
             output wire [15:0] o_result);
    
    assign o_result = {{8{i_insn[8]}}, i_insn[7:0]};

endmodule

module shift(input  wire [15:0] i_insn,
             input  wire [15:0] i_pc,
             input  wire [15:0] i_r1data,
             input  wire [15:0] i_r2data,
             output wire [15:0] o_result);
    
    wire [1:0] select;
    wire [15:0] iter0_shift8, iter1_shift4, iter2_shift2, iter3_shift1;
    wire [15:0] sll_iter1, sll_iter2, sll_iter3;
    wire [15:0] sra_iter0_shift8, sra_iter1_shift4, sra_iter2_shift2, sra_iter3_shift1;
    wire [15:0] sra_iter1, sra_iter2, sra_iter3;
    wire [15:0] srl_iter0_shift8, srl_iter1_shift4, srl_iter2_shift2, srl_iter3_shift1;
    wire [15:0] srl_iter1, srl_iter2, srl_iter3;
    wire [15:0] sll_result, sra_result, srl_result, mod_result, quotient;
    
    assign select = i_insn[5:4];
    
    assign iter0_shift8 = {i_r1data[7:0], 8'd0};
    assign sll_iter1 = i_insn[3] ? iter0_shift8 : i_r1data;
    assign iter1_shift4 = {sll_iter1[11:0], 4'd0};
    assign sll_iter2 = i_insn[2] ? iter1_shift4 : sll_iter1;
    assign iter2_shift2 = {sll_iter2[13:0], 2'd0};
    assign sll_iter3 = i_insn[1] ? iter2_shift2 : sll_iter2;
    assign iter3_shift1 = {sll_iter3[14:0], 1'd0};
    assign sll_result = i_insn[0] ? iter3_shift1 : sll_iter3;
    
    assign sra_iter0_shift8 = {{8{i_r1data[15]}}, i_r1data[15:8]};
    assign sra_iter1 = i_insn[3] ? sra_iter0_shift8 : i_r1data;
    assign sra_iter1_shift4 = {{4{sra_iter1[15]}}, sra_iter1[15:4]};
    assign sra_iter2 = i_insn[2] ? sra_iter1_shift4 : sra_iter1;
    assign sra_iter2_shift2 = {{2{sra_iter2[15]}}, sra_iter2[15:2]};
    assign sra_iter3 = i_insn[1] ? sra_iter2_shift2 : sra_iter2;
    assign sra_iter3_shift1 = {sra_iter3[15], sra_iter3[15:1]};
    assign sra_result = i_insn[0] ? sra_iter3_shift1 : sra_iter3;
    
    assign srl_iter0_shift8 = {8'd0, i_r1data[15:8]};
    assign srl_iter1 = i_insn[3] ? srl_iter0_shift8 : i_r1data;
    assign srl_iter1_shift4 = {4'd0, srl_iter1[15:4]};
    assign srl_iter2 = i_insn[2] ? srl_iter1_shift4 : srl_iter1;
    assign srl_iter2_shift2 = {2'd0, srl_iter2[15:2]};
    assign srl_iter3 = i_insn[1] ? srl_iter2_shift2 : srl_iter2;
    assign srl_iter3_shift1 = {1'd0, srl_iter3[15:1]};
    assign srl_result = i_insn[0] ? srl_iter3_shift1 : srl_iter3;
    
    lc4_divider mod(i_r1data, i_r2data, mod_result, quotient);
    
    assign o_result = (select == 2'd0) ? sll_result :
                      (select == 2'd1) ? sra_result :
                      (select == 2'd2) ? srl_result : mod_result;

endmodule

module jmps(input  wire [15:0] i_insn,
               input  wire [15:0] i_pc,
               input  wire [15:0] i_r1data,
               input  wire [15:0] i_r2data,
               output wire [15:0] o_result);
    
    wire jmp_select;
    wire [15:0] sext_IMM11, jmp_result;
    
    assign jmp_select = i_insn[11];
    
    assign sext_IMM11 = {{6{i_insn[10]}}, i_insn[9:0]};
    assign jmp_result = i_pc + 1 + sext_IMM11;
    
    assign o_result = jmp_select ? jmp_result : i_r1data;

endmodule

module hiconst(input  wire [15:0] i_insn,
               input  wire [15:0] i_pc,
               input  wire [15:0] i_r1data,
               input  wire [15:0] i_r2data,
               output wire [15:0] o_result);
               
    wire [15:0] rd_and;
    wire [15:0] shifted_UIMM8;
    
    assign rd_and = i_r1data & 16'h00FF;
    assign shifted_UIMM8 = {i_insn[7:0], 8'd0};
    
    assign o_result = rd_and | shifted_UIMM8;

endmodule

module trap(input  wire [15:0] i_insn,
            input  wire [15:0] i_pc,
            input  wire [15:0] i_r1data,
            input  wire [15:0] i_r2data,
            output wire [15:0] o_result);
               
    assign o_result = i_insn[7:0] | 16'h8000;

endmodule

module lc4_alu(input  wire [15:0] i_insn,
               input  wire [15:0] i_pc,
               input  wire [15:0] i_r1data,
               input  wire [15:0] i_r2data,
               output wire [15:0] o_result);
   
   wire [3:0] select;
   wire [15:0] branch_result, arith_result, compare_result, jsrs_result;
   wire [15:0] bool_logic_result, mem_result, rti_result, const_result;
   wire [15:0] shift_result, jmps_result, hiconst_result, trap_result;
   
   branch brancher(i_insn, i_pc, i_r1data, i_r2data, branch_result);
   arith arither(i_insn, i_pc, i_r1data, i_r2data, arith_result);
   compare comparer(i_insn, i_pc, i_r1data, i_r2data, compare_result);
   jsrs jsrser(i_insn, i_pc, i_r1data, i_r2data, jsrs_result);
   bool_logic logicker(i_insn, i_pc, i_r1data, i_r2data, bool_logic_result);
   mem memer(i_insn, i_pc, i_r1data, i_r2data, mem_result);
   rti rtier(i_insn, i_pc, i_r1data, i_r2data, rti_result);
   lc4_const conster(i_insn, i_pc, i_r1data, i_r2data, const_result);
   shift shifter(i_insn, i_pc, i_r1data, i_r2data, shift_result);
   jmps jmpser(i_insn, i_pc, i_r1data, i_r2data, jmps_result);
   hiconst hiconster(i_insn, i_pc, i_r1data, i_r2data, hiconst_result);
   trap trapper(i_insn, i_pc, i_r1data, i_r2data, trap_result);
   
   assign select = i_insn[15:12];
   
   assign o_result = (select == 4'd0) ? branch_result :
                     (select == 4'd1) ? arith_result :
                     (select == 4'd2) ? compare_result :
                     (select == 4'd4) ? jsrs_result :
                     (select == 4'd5) ? bool_logic_result :
                     (select == 4'd6) ? mem_result :
                     (select == 4'd7) ? mem_result :
                     (select == 4'd8) ? rti_result :
                     (select == 4'd9) ? const_result :
                     (select == 4'd10) ? shift_result :
                     (select == 4'd12) ? jmps_result :
                     (select == 4'd13) ? hiconst_result :
                     (select == 4'd15) ? trap_result : 16'd0;
                     

endmodule
