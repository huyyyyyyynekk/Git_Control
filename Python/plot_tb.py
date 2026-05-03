import numpy as np
import matplotlib.pyplot as plt
import os

# ==========================================
# CẤU HÌNH THÔNG SỐ (Giống y hệt phần mềm)
# ==========================================
SCALE_FACTOR = 512.0
THRESHOLD = 1536
C = -3328
D = 4096

class IzhikevichBitTrue:
    def __init__(self):
        self.v = -3328
        self.u = 0      
        self.FRAC = 9
        self.SCALE = 2

    def step(self, spike_in):
        # Bộ nhân phần cứng (mul16s_HF7) bỏ qua LSB (bit 0) của 2 toán hạng để tối ưu diện tích.
        # Do đó phải giả lập đúng sai số này trên phần mềm.
        v_trunc = self.v & ~1
        V_V = v_trunc * v_trunc
        
        input_term = 7680 if spike_in else 0
        
        dynamics = ((V_V >> (self.FRAC + self.SCALE)) + (self.v << 2) + self.v + 7168 - self.u + input_term) >> 1
        
        v_comb = self.v + dynamics
        u_comb = self.u + (((self.v >> 2) - self.u) >> 7)
        
        if v_comb >= THRESHOLD:
            self.v = C          
            self.u = u_comb + D 
        else:
            self.v = v_comb
            self.u = u_comb
            
        return v_comb / SCALE_FACTOR

sw_neuron = IzhikevichBitTrue()
sw_results = []

# ==========================================
# 1. TÍNH TOÁN SOFTWARE (Với cùng đầu vào I)
# ==========================================
# Giống hệt chuỗi kích thích trong tb_neuron.v (cứ 10 bước kích 1 spike)
spike_array = [1 if i % 1 == 0 else 0 for i in range(1000)]

for s_in in spike_array:
    sw_results.append(sw_neuron.step(s_in))

# ==========================================
# 2. ĐỌC DỮ LIỆU HARDWARE TỪ FILE TEXT
# ==========================================
hw_results = []
if not os.path.exists('hw_v_out.txt'):
    print(" LỖI: Không tìm thấy file hw_v_out.txt!")
    print(" Hãy chạy ModelSim bằng lệnh `vsim -do sim.do` trước để tạo file này.")
    exit(1)

with open('hw_v_out.txt', 'r') as f:
    for line in f:
        if line.strip():
            v_int = int(line.strip())
            # Verilog $fwrite in ra số âm bình thường với %d nếu khai báo là signed,
            # nhưng nếu nó in ra uint16, ta phải ép về int16
            if v_int >= 32768:
                v_int -= 65536
            hw_results.append(v_int / SCALE_FACTOR)

if len(hw_results) != len(sw_results):
    print(f" Cảnh báo: Chiều dài dữ liệu không khớp! HW có {len(hw_results)} mẫu, SW có {len(sw_results)} mẫu.")

# ==========================================
# 3. VẼ ĐỒ THỊ SO SÁNH
# ==========================================
plt.figure(figsize=(12, 5))
plt.plot(hw_results, label="Hardware (Verilog/ModelSim)", color='orange', linewidth=4, alpha=0.7)
plt.plot(sw_results[:len(hw_results)], label="Software (Python Golden)", color='blue', linestyle='--', linewidth=2)

plt.title("Hardware vs Software Verification (Offline Offline)")
plt.xlabel("Timesteps (1 tick = 0.5ms)")
plt.ylabel("Membrane Potential (Scaled)")
plt.grid(True, linestyle=':', alpha=0.7)
plt.legend()
plt.tight_layout()

print(" Đã hiển thị đồ thị so sánh (Hãy đóng cửa sổ hình để kết thúc).")
plt.show()
