module neuron_model #(
    parameter WIDTH = 16,
    parameter FRAC = 9,
    parameter SCALE = 2            
)(
    input  wire  clk,
    input  wire  rst_n,
    input  wire  en,
    input  wire  spike_in,
    input  wire signed [15:0] param_d,
    
    output reg   spike_out, 
    output wire signed [15:0] v_monitor,
    output reg   calc_done
);

    // ==========================================
    // CONSTANTS
    // ==========================================
    localparam signed [15:0] PARAM_C     = -16'sd3328;
    localparam signed [15:0] CONST_14    = 16'sd7168;
    localparam signed [15:0] THRESHOLD   = 16'sd1536;
    localparam signed [15:0] SYNAPSE_WT  = 16'sd7680; 

    // ==========================================
    // FSM
    // ==========================================
    localparam IDLE   = 2'd0;
    localparam STAGE1 = 2'd1;
    localparam STAGE2 = 2'd2;
    localparam STAGE3 = 2'd3;

    reg [1:0] state;

    // ==========================================
    // REGISTERS
    // ==========================================
    reg signed [15:0] v_reg, u_reg;

    reg signed [31:0] V_V_reg; 
    reg signed [15:0] input_term_reg;
    reg signed [15:0] v_comb_reg;
    reg signed [15:0] u_comb_reg;

    assign v_monitor = v_comb_reg;

    // ==========================================
    // MULTIPLIER INSTANCE
    // ==========================================
    wire signed [31:0] mul_out;

    mul16s_HF7 u_mul (
        .A(v_reg),
        .B(v_reg),
        .O(mul_out)
    );

    // ==========================================
    // FSM LOGIC
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            v_reg      <= PARAM_C;
            u_reg      <= 16'sd0;
            spike_out  <= 1'b0;
            calc_done  <= 1'b0;
        end 
        else begin
            case (state)
                IDLE: begin
                    calc_done <= 1'b0;
                    if (en) begin
                        state <= STAGE1;
                    end
                end

                // ---------------------------------
                // CLOCK 1: MULTIPLY
                // ---------------------------------
                STAGE1: begin
                    V_V_reg        <= mul_out;   // dùng module nhân
                    input_term_reg <= spike_in ? SYNAPSE_WT : 16'sd0;
                    state          <= STAGE2;
                end

                // ---------------------------------
                // CLOCK 2
                // ---------------------------------
                STAGE2: begin
                    v_comb_reg <= v_reg + 
                        ((((V_V_reg >>> (FRAC + SCALE)) 
                        + (v_reg <<< 2) 
                        + v_reg 
                        + CONST_14 
                        - u_reg) 
                        + input_term_reg) >>> 1);

                    u_comb_reg <= u_reg + (((v_reg >>> 2) - u_reg) >>> 7);

                    state <= STAGE3;
                end

                // ---------------------------------
                // CLOCK 3
                // ---------------------------------
                STAGE3: begin
                    if (v_comb_reg >= THRESHOLD) begin  
                        v_reg     <= PARAM_C;          
                        u_reg     <= u_comb_reg + param_d;
                        spike_out <= 1'b1;        
                    end 
                    else begin
                        v_reg     <= v_comb_reg;
                        u_reg     <= u_comb_reg;
                        spike_out <= 1'b0;
                    end
                    
                    calc_done <= 1'b1;
                    state     <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule