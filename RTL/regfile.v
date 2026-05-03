module regfile (
    input  wire        clk,
    input  wire        rst_n,
    
    // Interface với UART
    input  wire        uart_we,      // Cờ cho phép ghi từ UART
    input  wire [15:0] uart_wdata,   // Dữ liệu D từ PC gửi xuống
    
    // Interface với Nút bấm (đã qua chống dội)
    input  wire        btn_tick,     // Xung khi bấm nút S1
    
    // Output cấp cho Nơ-ron
    output wire signed [15:0] param_d
);

    reg signed [15:0] reg_d;
    reg [1:0]         btn_idx; // Biến đếm vòng lặp cho nút bấm

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_d   <= 16'sd4096; // Giá trị mặc định
            btn_idx <= 2'd0;
        end else begin
            // ƯU TIÊN 1: Lệnh cấu hình từ PC (Ghi đè mọi thứ)
            if (uart_we) begin
                reg_d   <= uart_wdata;
                btn_idx <= 2'd0; // Tùy chọn: Reset lại vòng lặp nút bấm
            end 
            // ƯU TIÊN 2: Bấm nút cứng trên board
            else if (btn_tick) begin
                if (btn_idx == 2'd0) begin
                    btn_idx <= 2'd1;
                    reg_d   <= 16'sd576;
                end else if (btn_idx == 2'd1) begin
                    btn_idx <= 2'd2;
                    reg_d   <= 16'sd192;
                end else begin
                    btn_idx <= 2'd0;
                    reg_d   <= 16'sd4096;
                end
            end
        end
    end

    assign param_d = reg_d;

endmodule