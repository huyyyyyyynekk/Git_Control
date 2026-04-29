## Mục lục

* [PHẦN 1: Cấu trúc hệ thống phần cứng (FPGA Gowin Kiwi 1p5)](#phần-1-cấu-trúc-hệ-thống-phần-cứng-fpga-gowin-kiwi-1p5)

  * [Giao thức UART 4-Bytes](#giao-thức-uart-4-bytes)
  * [Cơ chế cập nhật tham số](#cơ-chế-cập-nhật-tham-số)
  * [Pinout (FPGA Gowin Kiwi 1p5)](#pinout-fpga-gowin-kiwi-1p5)


* [PHẦN 2: Giao tiếp phía PC (Python)](#giao-tiếp-phía-pc-python)
  
  * [Giao diện hiển thị](#giao-diện-hiển-thị)
  * [Hướng dẫn chạy](#hướng-dẫn-chạy)


## PHẦN 1: Cấu trúc hệ thống phần cứng (FPGA Gowin Kiwi 1p5)

### Pinout & Phần cứng

| Tín hiệu    | Pin | IO Type  | Pull Mode | Drive | Điện áp | Mô tả               |
| ----------- | --- | -------- | --------- | ----- | ------- | ------------------- |
| `clk`       | 4   | LVCMOS33 | UP        | —     | 3.3V    | Clock hệ thống      |
| `rst_n`     | 35  | LVCMOS33 | UP        | —     | 3.3V    | Reset (active low)  |
| `S1`        | 36  | LVCMOS33 | UP        | —     | 3.3V    | Nút nhấn người dùng |
| `rx_serial` | 33  | LVCMOS33 | NONE      | —     | 3.3V    | UART RX (PC → FPGA) |
| `tx_serial` | 34  | LVCMOS33 | NONE      | 8     | 3.3V    | UART TX (FPGA → PC) |


### Giao thức UART 4-Bytes

Hệ thống sử dụng giao thức UART để truyền dữ liệu thời gian thực giữa FPGA và máy tính.
Mỗi chu kỳ truyền, dữ liệu được đóng gói thành một gói **32-bit (4 bytes)** gồm:

* **2 bytes cao**: tham số phục hồi `D`
* **2 bytes thấp**: điện thế màng `V`

Trong file `uart_top.v`, FSM thực hiện đóng gói dữ liệu:

```verilog
CAPTURE: begin
    // Đóng gói 4 bytes: [D_high][D_low][V_high][V_low]
    tx_packet <= {current_d_from_rf, v_monitor};
    state     <= TX_RESULT;
end
```

Cách đóng gói này giúp phía PC luôn biết trạng thái neuron (`V`) tương ứng với tham số (`D`) mà không cần truy vấn thêm.

---

### Cơ chế cập nhật tham số

Hệ thống hỗ trợ hai cách thay đổi tham số `D`:

1. **Từ PC qua UART (ưu tiên cao nhất)**
2. **Thông qua nút nhấn trên board**

```verilog
// ƯU TIÊN 1: UART
if (uart_we) begin
    reg_d   <= uart_wdata;
    btn_idx <= 2'd0; 
end 
// ƯU TIÊN 2: Button
else if (btn_tick) begin
    if (btn_idx == 2'd0) begin
        btn_idx <= 2'd1;
        reg_d   <= 16'sd576;
    end
    // ...
end
```

Cơ chế này cho phép chuyển đổi linh hoạt giữa điều khiển bằng phần mềm và phần cứng.

---

## PHẦN 2: Giao tiếp phía PC (Python)

```python
# Gửi tín hiệu đầu vào
ser.write(bytes([s_in]))

# Đọc 4 bytes từ UART
raw_bytes = ser.read(4)

if len(raw_bytes) == 4:
    # Giải mã: 2 số int16 có dấu (Little Endian)
    v_int, hw_d = struct.unpack('<hh', raw_bytes)

    hw_results.append(v_int / SCALE_FACTOR)

    # Đồng bộ tham số D từ phần cứng
    sw_neuron.D = hw_d
```

* `V` được scale về giá trị thực
* `D` từ FPGA được đồng bộ trực tiếp vào mô hình phần mềm

---

### Giao diện hiển thị

* Sử dụng **PyQt5** để xây dựng GUI
* Sử dụng **pyqtgraph** để hiển thị đồ thị thời gian thực

---

### Hướng dẫn chạy

1. Nạp bitstream bằng Gowin IDE
2. Sửa `COM_PORT` trong `python_test_4.py`
3. Chạy:

```bash
python python_test_4.py
```

Sau khi chạy:

* FPGA gửi dữ liệu neuron qua UART
* Python nhận và xử lý
* GUI hiển thị tín hiệu theo thời gian thực

