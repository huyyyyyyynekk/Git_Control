import serial
import struct
import numpy as np
import pyqtgraph as pg
from pyqtgraph.Qt import QtCore, QtWidgets
import sys
import time

# ==========================================
# CẤU HÌNH THÔNG SỐ
# ==========================================
COM_PORT = 'COM9'
BAUD_RATE = 115200
FRAC_BITS = 9
SCALE_FACTOR = 2**FRAC_BITS 

DT = 0.5           
C = -3328
THRESHOLD = 1536   
WINDOW_SIZE = 1000 
FPS = 30
CHUNK_SIZE = int(2000 / FPS) 

# ==========================================
# MÔ HÌNH SOFTWARE
# ==========================================
class IzhikevichBitTrue:
    def __init__(self):
        self.v = -3328  
        self.u = 0      
        self.FRAC = 9
        self.SCALE = 2
        self.D = 4096 

    def step(self, spike_in):
        v_trunc = self.v & ~1
        V_V = v_trunc * v_trunc
        input_term = 7680 if spike_in else 0
        
        dynamics = ((V_V >> (self.FRAC + self.SCALE)) + (self.v << 2) + self.v + 7168 - self.u + input_term) >> 1
        v_comb = self.v + dynamics
        u_comb = self.u + (((self.v >> 2) - self.u) >> 7)
        
        if v_comb >= THRESHOLD:
            self.v = C          
            self.u = u_comb + self.D 
        else:
            self.v = v_comb
            self.u = u_comb
            
        return v_comb / SCALE_FACTOR

def update_hardware_d(ser, new_d):
    packet = bytes([0x02]) + struct.pack('>h', new_d)
    ser.write(packet)
    time.sleep(0.01)

# ==========================================
# GIAO DIỆN GUI
# ==========================================
app = QtWidgets.QApplication(sys.argv)
win = QtWidgets.QWidget()
win.setWindowTitle("SparkWave: Auto-Sync Hardware & Software")
win.resize(1200, 700)

main_layout = QtWidgets.QVBoxLayout()
win.setLayout(main_layout)

plot_widget = pg.PlotWidget(title=f"Real-time Comparison (dt={DT}ms)")
plot_widget.setYRange(-90, 50)
plot_widget.addLegend()
plot_widget.showGrid(x=True, y=True)
main_layout.addWidget(plot_widget)

h_data = np.full(WINDOW_SIZE, -6.5)
h_curve = plot_widget.plot(h_data, pen=pg.mkPen('y', width=2), name="Hardware (FPGA)")

s_data = np.full(WINDOW_SIZE, -6.5)
s_curve = plot_widget.plot(s_data, pen=pg.mkPen('r', width=1, style=QtCore.Qt.DashLine), name="Software (Golden Model)")

ctrl_layout = QtWidgets.QHBoxLayout()
main_layout.addLayout(ctrl_layout)

lbl_uart = QtWidgets.QLabel("Ghi đè D toàn hệ thống:")
input_d = QtWidgets.QLineEdit()
input_d.setPlaceholderText("Nhập giá trị D (VD: 8000)")
btn_uart_sync = QtWidgets.QPushButton("Gửi UART")

# Nhãn hiển thị trạng thái D Đang Đọc Từ Phần Cứng
lbl_hw_status = QtWidgets.QLabel("Tham số D từ mạch: Đang chờ...")
lbl_hw_status.setStyleSheet("color: #00FF00; font-weight: bold; background: #222; padding: 5px;")

ctrl_layout.addWidget(lbl_uart)
ctrl_layout.addWidget(input_d)
ctrl_layout.addWidget(btn_uart_sync)
ctrl_layout.addStretch()
ctrl_layout.addWidget(lbl_hw_status)

def on_uart_sync():
    try:
        new_d = int(input_d.text())
        update_hardware_d(ser, new_d)
        input_d.clear()
    except ValueError:
        print("Lỗi: Nhập số nguyên!")

input_d.returnPressed.connect(on_uart_sync)
btn_uart_sync.clicked.connect(on_uart_sync)

# ==========================================
# VÒNG LẶP GIAO TIẾP VÀ MÔ PHỎNG
# ==========================================
sw_neuron = IzhikevichBitTrue()
try:
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=0.1)
    # Không cần set cứng ban đầu nữa, vì vòng lặp sẽ tự động đọc D từ mạch về
except Exception as e:
    print(f"Lỗi cổng COM: {e}")
    sys.exit()

spike_array = [1 if i % 15 == 0 else 0 for i in range(100000)]
spike_idx = 0

def update():
    global h_data, s_data, spike_idx
    if spike_idx >= len(spike_array):
        timer.stop()
        return

    sw_results = []
    hw_results = []
    current_chunk = min(CHUNK_SIZE, len(spike_array) - spike_idx)
    latest_hw_d = None
    
    for _ in range(current_chunk):
        s_in = spike_array[spike_idx]
        
        # 1. Tính toán Software (Sử dụng D đang có sẵn)
        sw_v = sw_neuron.step(s_in)
        sw_results.append(sw_v)
        
        # 2. Giao tiếp Hardware
        ser.write(bytes([s_in]))
        raw_bytes = ser.read(4) # ĐỌC 4 BYTES THAY VÌ 2
        
        if len(raw_bytes) == 4:
            # Giải mã 4 bytes: '<hh' nghĩa là 2 số short (16-bit) có dấu, Little Endian
            v_int, hw_d = struct.unpack('<hh', raw_bytes)
            hw_results.append(v_int / SCALE_FACTOR)
            
            # CẬP NHẬT TỰ ĐỘNG THÔNG SỐ D CHO PHẦN MỀM
            sw_neuron.D = hw_d 
            latest_hw_d = hw_d
        else:
            hw_results.append(-65.0) 
            
        spike_idx += 1
        
    # Cập nhật GUI
    if latest_hw_d is not None:
        lbl_hw_status.setText(f"Tham số D từ mạch: {latest_hw_d}")

    h_data[:-current_chunk] = h_data[current_chunk:]
    h_data[-current_chunk:] = hw_results
    
    s_data[:-current_chunk] = s_data[current_chunk:]
    s_data[-current_chunk:] = sw_results
    
    h_curve.setData(h_data)
    s_curve.setData(s_data)

timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(int(1000/FPS))

win.show()
if __name__ == '__main__':
    sys.exit(app.exec_())