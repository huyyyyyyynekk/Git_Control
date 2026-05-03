module uart_top #(
    parameter CLKS_PER_BIT = 234
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rx_serial,
    input  wire S1,           
    output wire tx_serial
);
    wire signed [15:0] v_monitor;
    wire spike_out;
    wire       rx_valid;
    wire [7:0] rx_data;
    wire       tx_busy;
    wire       neuron_done;

    reg [2:0]  state;
    reg [3:0]  byte_count;   
    reg        tx_start_reg;
    reg [7:0]  tx_data_reg;
    
    // THANH GHI MỚI CHỨA GÓI TIN 4 BYTES
    reg [31:0] tx_packet; 
    
    reg        neuron_en;
    reg        spike_from_pc;
    reg        rf_uart_we;
    reg [7:0]  temp_d_high;
    wire signed [15:0] current_d_from_rf;
    wire s1_tick;

    localparam WAIT_CMD  = 3'd0;
    localparam RECV_D_H  = 3'd1;
    localparam RECV_D_L  = 3'd2;
    localparam COMPUTE   = 3'd3;
    localparam CAPTURE   = 3'd4;
    localparam TX_RESULT = 3'd5;

    button_debouncer u_btn (.clk(clk), .rst_n(rst_n), .btn_in(S1), .btn_tick(s1_tick));

    regfile u_rf (
        .clk(clk), .rst_n(rst_n),
        .uart_we(rf_uart_we),
        .uart_wdata({temp_d_high, rx_data}), 
        .btn_tick(s1_tick),
        .param_d(current_d_from_rf)
    );

    neuron_model u_neuron (
        .clk(clk), .rst_n(rst_n), .en(neuron_en), .spike_in(spike_from_pc), 
        .param_d(current_d_from_rf), 
        .spike_out(spike_out), .v_monitor(v_monitor),
        .calc_done(neuron_done)
    );

    UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (.clk(clk), .rst_n(rst_n), .rx_serial(rx_serial), .rx_data(rx_data), .rx_valid(rx_valid));
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (.clk(clk), .rst_n(rst_n), .tx_data(tx_data_reg), .tx_start(tx_start_reg), .tx_serial(tx_serial), .tx_busy(tx_busy));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= WAIT_CMD;
            tx_packet     <= 32'd0;
            byte_count    <= 4'd0;
            tx_start_reg  <= 1'b0;
            tx_data_reg   <= 8'd0;
            neuron_en     <= 1'b0;
            spike_from_pc <= 1'b0;
            rf_uart_we    <= 1'b0;
            temp_d_high   <= 8'd0;
        end else begin
            neuron_en  <= 1'b0;
            rf_uart_we <= 1'b0; 

            case (state)
                WAIT_CMD: begin
                    if (rx_valid) begin
                        if (rx_data == 8'h02) state <= RECV_D_H;
                        else begin
                            spike_from_pc <= rx_data[0];
                            neuron_en     <= 1'b1;
                            state         <= COMPUTE;
                        end
                    end
                end

                RECV_D_H: begin
                    if (rx_valid) begin temp_d_high <= rx_data; state <= RECV_D_L; end
                end

                RECV_D_L: begin
                    if (rx_valid) begin rf_uart_we <= 1'b1; state <= WAIT_CMD; end
                end

                COMPUTE: begin
                    if (neuron_done) state <= CAPTURE;
                end

                CAPTURE: begin
                    // Đóng gói 4 bytes: [Byte3: D_high] [Byte2: D_low] [Byte1: V_high] [Byte0: V_low]
                    tx_packet <= {current_d_from_rf, v_monitor};
                    state     <= TX_RESULT;
                end

                TX_RESULT: begin
                    // ĐỔI ĐIỀU KIỆN LÊN 4 BYTES
                    if (byte_count < 4'd4) begin
                        if (!tx_start_reg && !tx_busy) begin
                            tx_data_reg  <= tx_packet[byte_count*8 +: 8];
                            tx_start_reg <= 1'b1;
                        end else if (tx_start_reg && tx_busy) begin
                            tx_start_reg <= 1'b0;
                            byte_count   <= byte_count + 4'd1;
                        end
                    end else if (!tx_busy) begin
                        byte_count <= 4'd0;
                        state      <= WAIT_CMD; 
                    end
                end

                default: state <= WAIT_CMD;
            endcase
        end
    end
endmodule