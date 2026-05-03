`timescale 1ns/1ps

module tb_neuron;

    reg clk;
    reg rst_n;
    reg en;
    reg spike_in;
    
    wire spike_out;
    wire signed [15:0] v_monitor;
    wire calc_done;

    // Khởi tạo model phần cứng
    neuron_model #(
        .WIDTH(16),
        .FRAC(9),
        .SCALE(2)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .spike_in(spike_in),
        .spike_out(spike_out),
        .v_monitor(v_monitor),
        .calc_done(calc_done)
    );

    // Tạo xung nhịp 27MHz (chu kỳ ~37ns)
    initial clk = 0;
    always #18.5 clk = ~clk;

    integer fd;
    integer i;

    initial begin
        // Mở file để ghi kết quả v_monitor
        fd = $fopen("hw_v_out.txt", "w");
        if (fd == 0) begin
            $display("Không thể tạo file hw_v_out.txt!");
            $finish;
        end

        // Reset hệ thống
        rst_n = 0;
        en = 0;
        spike_in = 0;
        
        #100;
        rst_n = 1;
        #100;

        // Bắt đầu mô phỏng 1000 timesteps
        for (i = 0; i < 1000; i = i + 1) begin
            @(posedge clk);
            
            // Tạo tín hiệu dòng I (spike_in)
            // Ví dụ: Cứ 10 nhịp thì kích 1 spike
            if (i % 1 == 0) 
                spike_in = 1;
            else 
                spike_in = 0;

            en = 1; // Kích hoạt neuron tính toán
            @(posedge clk);
            en = 0;

            // Đợi cho neuron tính xong (calc_done cờ lên 1)
            wait(calc_done == 1'b1);
            
            // Đợi thêm 1 chu kỳ clock để thanh ghi v_reg cập nhật xong (Giống hệt uart_top.v)
            @(posedge clk); 
            
            // Ghi giá trị v_monitor ra file text
            $fwrite(fd, "%d\n", v_monitor);
            
            // Nghỉ 1 chút trước khi cấp mẫu tiếp theo
            #100;
        end

        $fclose(fd);
        $display("Mô phỏng hoàn tất. Đã lưu dữ liệu vào hw_v_out.txt");
        $finish;
    end

endmodule
