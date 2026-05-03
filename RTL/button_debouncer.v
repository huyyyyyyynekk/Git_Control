module button_debouncer #(
    parameter CLK_FREQ = 27_000_000, // Tần số thạch anh (VD: 50MHz)
    parameter DEBOUNCE_MS = 20       // Thời gian lọc nhiễu: 20ms
)(
    input  wire clk,
    input  wire rst_n,
    input  wire btn_in,    // Tín hiệu thô từ nút bấm S1
    output reg  btn_tick   // Xung sạch 1 chu kỳ clock khi phát hiện bấm
);
    localparam MAX_COUNT = CLK_FREQ / 1000 * DEBOUNCE_MS;
    
    reg [31:0] counter;
    reg sync_0, sync_1;
    reg btn_state;

    // 2-stage synchronizer: Chống Metastability khi đưa tín hiệu ngoài vào miền clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 1'b1; 
            sync_1 <= 1'b1;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;
        end
    end

    // Logic lọc nhiễu và tạo xung (Edge Detection)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 0;
            btn_state <= 1'b1;
            btn_tick  <= 1'b0;
        end else begin
            btn_tick <= 1'b0; // Mặc định luôn bằng 0
            
            if (sync_1 != btn_state) begin
                if (counter < MAX_COUNT) begin
                    counter <= counter + 1;
                end else begin
                    btn_state <= sync_1;
                    counter   <= 0;
                    // Bắt sườn xuống (từ 1 -> 0 do ấn nút)
                    if (sync_1 == 1'b0) begin 
                        btn_tick <= 1'b1; // Tạo 1 xung tick
                    end
                end
            end else begin
                counter <= 0;
            end
        end
    end
endmodule