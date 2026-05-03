module uart_tx #(
    parameter CLKS_PER_BIT = 234
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_serial,
    output reg        tx_busy
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  tx_shift;
    reg        tx_serial_reg;
    reg        tx_start_d;

    assign tx_serial = tx_serial_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            clk_count     <= 16'd0;
            bit_index     <= 3'd0;
            tx_shift      <= 8'd0;
            tx_serial_reg <= 1'b1;
            tx_busy       <= 1'b0;
            tx_start_d    <= 1'b0;
        end else begin
            tx_start_d <= tx_start;

            case (state)
                IDLE: begin
                    tx_serial_reg <= 1'b1;
                    clk_count     <= 16'd0;
                    bit_index     <= 3'd0;
                    if (tx_start && !tx_start_d) begin
                        tx_shift <= tx_data;
                        tx_busy  <= 1'b1;
                        state    <= START;
                    end
                end

                START: begin
                    tx_serial_reg <= 1'b0;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        state     <= DATA;
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                DATA: begin
                    tx_serial_reg <= tx_shift[0];
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        tx_shift  <= {1'b0, tx_shift[7:1]};
                        if (bit_index == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                STOP: begin
                    tx_serial_reg <= 1'b1;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        tx_busy   <= 1'b0;
                        state     <= IDLE;
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
