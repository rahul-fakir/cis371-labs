`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input  wire        rst,                // global reset
    input  wire        gwe,                // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory
   
    output wire [1:0]  test_stall,         // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
   
    // State of the zedboard switches, LCD and LEDs
    // You are welcome to use the Zedboard's LCD number display and LEDs
    // for debugging purposes, but it isn't terribly useful.  Ditto for
    // reading the switch positions from the Zedboard

    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [15:0] seven_segment_data, // Data to display to the Zedboard LCD
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?

    );
         
    // TODO: Verify all code below 
    // TODO: Handle Branch Prediction/Squashing/etc. 
   
    // Notes: Set "test_" wires at writeback stage 
    // Notes: Set "o_dmem_*" wires in memory stage 
    // Notes: Braching works as follows: predict "not-taken", meaning assume 
    //          next_pc = pc+1, for all instructions, if in the execute (X)stage
    //          a branch is taken then we must fill the Fetch and Decode stages with NOP's
   
    /***** FETCH STAGE *****/  
    wire[15:0] f_in_pc, f_pc;
    wire[15:0] f_insn;
    wire[2:0] f_stall;
       
    // Nbit_reg #(16, 16'h0) f_latch_insn (.in(i_cur_insn), .out(f_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    assign f_insn = i_cur_insn; 
                                        
    Nbit_reg #(16, 16'h8200) pc_reg (.in(f_in_pc), .out(f_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    assign o_cur_pc = f_pc;
    assign f_in_pc = o_cur_pc + 16'b1;

    assign f_stall = f_insn == 16'b0 ? 2'd2 : 
                 f_insn == 16'b0 ? 2'd3 : 2'd0; // TODO: correct(fix) condition logic

    // Nbit_reg #(16, 16'h0) f_latch_pc (.in(o_cur_pc), .out(f_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /***** DECODE STAGE *****/
    wire[15:0] d_initial_insn, d_final_insn;
    wire[15:0] d_pc;
    wire[2:0] d_rs, d_rt, d_rd;
    wire d_r1_re, d_r2_re, d_regfile_we, d_nzp_we, d_pcplusone, d_is_load, d_is_store, d_is_branch, d_is_control_insn;
    wire[2:0] d_stall;

    // Preview of Execute for stall:
    wire[15:0] x_insn;
    wire[2:0] x_rd;
    
    // Decode registers
    Nbit_reg #(16, 16'h0) d_latch_insn (.in(f_insn), .out(d_initial_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // is there a we other than gwe?
    Nbit_reg #(16, 16'h0) d_latch_pc (.in(f_pc), .out(d_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // TODO: change names, check we again?
    Nbit_reg #(2, 2'd2) d_latch_test_stall (.in(f_stall), .out(d_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    /* hazard block */
    wire is_nop = x_insn[15:12] == 4'b0110 & (d_rs == x_rd | (d_rt == x_rd & d_initial_insn[15:12] != 4'b0111));
    assign d_final_insn = is_nop ? 16'b0 : d_initial_insn; // load to use stall hazard
        
    /* decoder */
    lc4_decoder d_latch_insn_decoder(d_final_insn, d_rs, d_r1_re, d_rt, d_r2_re, d_rd, d_regfile_we, d_nzp_we,
                                     d_pcplusone, d_is_load, d_is_store, d_is_branch, d_is_control_insn);
                      
    /* regfile */
    wire [15:0] d_towrite, d_r1_data, d_r2_data, d_r1_data_bypassed, d_r2_data_bypassed;
    lc4_regfile #(16) regfile(clk, gwe, rst, d_rs, d_r1_data, d_rt, d_r2_data, w_rd, d_towrite, w_regfile_we); // Nik: made change from d_regfile_we to w_regfile_we 
   
   /***** EXECUTE STAGE *****/
    wire[15:0] x_pc;
    wire[2:0] x_rs;
    wire[2:0] x_rt;
    wire[15:0] x_r1_data;
    wire[15:0] x_r2_data;
    wire x_nzp_we;
    wire x_pcplusone;
    wire x_is_load;
    wire x_is_store;
    wire x_is_branch;
    wire x_is_control_insn;
    wire[15:0] x_r1_data_bypassed;
    wire[15:0] x_r2_data_bypassed;
    wire[15:0] x_alu_output;
    wire[2:0] x_stall;
    wire x_regfile_we;
   
    // TODO: add all execute registers
    Nbit_reg #(16, 16'h0) x_latch_insn (.in(d_final_insn), .out(x_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) x_latch_pc (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) x_latch_rs (.in(d_rs), .out(x_rs), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) x_latch_rt (.in(d_rt), .out(x_rt), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) x_latch_rd (.in(d_rd), .out(x_rd), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) x_latch_r1_data (.in(d_r1_data_bypassed), .out(x_r1_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) x_latch_r2_data (.in(d_r2_data_bypassed), .out(x_r2_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) x_latch_nzp_we (.in(d_nzp_we), .out(x_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) x_latch_pcplusone (.in(d_pcplusone), .out(x_pcplusone), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) x_latch_is_load (.in(d_is_load), .out(x_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) x_latch_is_store (.in(d_is_store), .out(x_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) x_latch_is_branch (.in(d_is_branch), .out(x_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) x_latch_is_control_insn (.in(d_is_control_insn), .out(x_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'd2) x_latch_test_stall (.in(d_stall), .out(x_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'd0) x_latch_regfile_we (.in(d_regfile_we), .out(x_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
    lc4_alu x_alu(x_insn, x_pc, x_r1_data_bypassed, x_r2_data_bypassed, x_alu_output);
   
   /***** MEMORY STAGE *****/
    wire[15:0] m_insn;
    wire[15:0] m_pc;
    wire[15:0] m_alu_output;
    wire[15:0] m_data;
    wire[2:0] m_rs;
    wire[2:0] m_rt;
    wire[2:0] m_rd;
    wire m_nzp_we;
    wire m_pcplusone;
    wire m_is_load;
    wire m_is_store;
    wire m_is_branch;
    wire m_is_control_insn;
    wire[15:0] m_data_bypassed;
    wire[15:0] m_dmem_addr;
    wire[15:0] m_dmem_output;
    wire[2:0] m_stall;
    wire m_regfile_we;
    
    wire is_program_start = m_insn == 16'b0; // what is this?
   
    // TODO: add all mem registers
    Nbit_reg #(16, 16'h0) m_latch_insn (.in(x_insn), .out(m_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) m_latch_pc (.in(x_pc), .out(m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) m_latch_alu_output (.in(x_alu_output), .out(m_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) m_latch_data (.in(x_r2_data_bypassed), .out(m_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) m_latch_rs (.in(x_rs), .out(m_rs), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) m_latch_rt (.in(x_rt), .out(m_rt), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) m_latch_rd (.in(x_rd), .out(m_rd), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) m_latch_nzp_we (.in(x_nzp_we), .out(m_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) m_latch_pcplusone (.in(x_pcplusone), .out(m_pcplusone), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) m_latch_is_load (.in(x_is_load), .out(m_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) m_latch_is_store (.in(x_is_store), .out(m_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) m_latch_is_branch (.in(x_is_branch), .out(m_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) m_latch_is_control_insn (.in(x_is_control_insn), .out(m_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'd2) m_latch_test_stall (.in(x_stall), .out(m_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'd0) m_latch_regfile_we (.in(x_regfile_we), .out(m_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    /* START: NZP (unsure if it needs further modification from lc4_single.v -- should it even be in this stage?) */
        
    /* END: NZP (unsure if it needs further modification from lc4_single.v -- should it even be in this stage?) */
    
    assign m_dmem_addr = (m_is_load | m_is_store) ? m_alu_output : 16'h0000; 
    assign o_dmem_we = m_is_store;
    assign o_dmem_towrite = m_data_bypassed;
    assign m_dmem_output = m_is_load ? i_cur_dmem_data : 16'h0000;
   
   /***** WRITEBACK STAGE *****/
    wire[15:0] w_pc;
    wire[15:0] w_insn;
    wire[15:0] w_alu_output;
    wire[15:0] w_dmem_output;
    wire w_is_load;
    wire[2:0] w_rd;
    wire[15:0] w_mux_output;
    wire[2:0] w_stall;
    wire w_regfile_we;
   
    // TODO: add all writeback registers
    Nbit_reg #(16, 16'h0) w_latch_insn (.in(m_insn), .out(w_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) w_latch_pc (.in(m_pc), .out(w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) w_latch_alu_output (.in(m_alu_output), .out(w_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) w_latch_dmem_output (.in(m_dmem_output), .out(w_dmem_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) w_latch_is_load (.in(m_is_load), .out(w_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) w_latch_rd (.in(m_rd), .out(w_rd), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'd2) w_latch_test_stall (.in(m_stall), .out(w_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'd0) w_latch_regfile_we (.in(m_regfile_we), .out(w_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    assign w_mux_output = w_is_load ? w_dmem_output : w_alu_output;
    assign d_towrite = w_mux_output;
    
    /****** NZP *****/
    
    wire [2:0] br_nzp, nzp_new_bits;
    assign nzp_new_bits = (d_towrite[15] == 1'b1) ? 3'b100 : 
                          (d_towrite == 16'd0) ? 3'b010 : 3'b001;                                                                      
    Nbit_reg #(3) nzp_reg(nzp_new_bits, br_nzp, clk, m_nzp_we, gwe, rst);
    wire is_nzp_taken = (br_nzp[2] & w_insn[11]) | (br_nzp[1] & w_insn[10]) | (br_nzp[0] & w_insn[9]);

    
    /****** BYPASSES *******/
    assign d_r1_data_bypassed = (d_rs == w_rd) & (w_regfile_we) ? d_towrite : d_r1_data;
    
    assign d_r2_data_bypassed = (d_rt == w_rd) & (w_regfile_we) ? d_towrite : d_r2_data;
    
    assign x_r1_data_bypassed = (x_rs == m_rd) & (m_regfile_we) ? m_alu_output : 
                                (x_rs == w_rd) & (w_regfile_we) ? d_towrite : 
                                x_r1_data;
    
    assign x_r2_data_bypassed = (x_rt == m_rd) & (m_regfile_we) ? m_alu_output : 
                                (x_rt == w_rd) & (w_regfile_we) ? d_towrite : 
                                x_r2_data;
                                
    assign m_data_bypassed = (m_is_store & m_rs == w_rd) ? w_mux_output : m_data;
                           
    /* test wires */
    
//    Nbit_reg #(16, 16'h0) test_latch_insn (.in(w_insn), .out(test_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//    Nbit_reg #(16, 16'h0) test_latch_pc (.in(w_pc), .out(test_cur_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign test_stall = w_stall;
    assign test_cur_pc = w_pc;
    assign test_cur_insn = w_insn;
    assign test_regfile_we = w_regfile_we;
    assign test_regfile_wsel = w_rd;
    assign test_regfile_data = w_mux_output; 
    assign test_nzp_we = 1'b1;        // Testbench: NZP condition codes write enable
    assign test_nzp_new_bits = nzp_new_bits;  // Testbench: value to write to NZP bits
    assign test_dmem_we = o_dmem_we;
    assign test_dmem_addr = m_dmem_addr;
    assign test_dmem_data = w_dmem_output;

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
       // $display("%d fin %h ocur %h fpc %h d %h x %h m %h w %h", $time, f_in_pc, o_cur_pc, f_pc, d_pc, x_pc, m_pc, w_pc);
       
       // $display("%d %h %h %h ", $time, i_cur_dmem_data, m_dmem_output, w_dmem_output);
       
       $display("%d x: %d %d %d", $time, x_rs, x_rt, x_rd);
       $display("%d m: %d %d %d", $time, m_rs, m_rt, m_rd);
       $display("%d w_rd: %d", $time, w_rd);
       
       $display("%d ALUs: %h %h %h", $time, x_alu_output, m_alu_output, d_towrite);
       
       // $display("%d %b %b %b %b %b", $time, f_stall, d_stall, x_stall, m_stall, w_stall);
              
      // $display("%b %b %b %b %b", x_rs, x_rt, m_rd, x_alu_output, m_alu_output);
      
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      $display("input insn:  %b ", i_cur_insn);
      $display("f insn:  %b ", f_insn); 
      $display("d insn: %b  ", d_final_insn); 
      $display("x insn:  %b ", x_insn); 
      $display("m insn:  %b ", m_insn); 
      $display("w insn:  %b ", w_insn); 

   end
`endif
endmodule
