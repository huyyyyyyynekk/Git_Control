module tb;
  reg signed [15:0] v_reg;
  reg signed [31:0] V_V_reg;
  reg signed [15:0] u_reg;
  reg signed [15:0] input_term_reg;
  reg signed [31:0] expr1;
  reg signed [31:0] expr2;
  reg signed [15:0] CONST_14;

  initial begin
    v_reg = -16'sd3328;
    V_V_reg = 11075584; // 3328*3328
    u_reg = 0;
    input_term_reg = 0;
    CONST_14 = 7168;

    expr1 = (V_V_reg >>> 11) + (v_reg <<< 2) + v_reg + CONST_14 - u_reg + input_term_reg;
    $display("expr1 (verilog): %d", expr1);
    
    v_reg = -16'sd8192; // 8192 << 2 = 32768, which is -32768 in 16-bit signed, but in 32-bit it's -32768. Wait. Let's use 10000.
    v_reg = -16'sd10000; // 10000 << 2 = 40000, 16-bit signed = 40000 - 65536 = -25536. 
                         // -10000 << 2 = -40000, 16-bit signed = 65536 - 40000 = 25536.
    expr1 = (v_reg <<< 2);
    expr2 = (V_V_reg >>> 11) + (v_reg <<< 2);
    $display("-10000 <<< 2 in 32-bit context: %d", expr2 - (V_V_reg >>> 11));
    $finish;
  end
endmodule
