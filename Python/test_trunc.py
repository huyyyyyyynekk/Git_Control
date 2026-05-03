import struct

def to_int16(val):
    val = int(val) & 0xFFFF
    if val >= 0x8000:
        val -= 0x10000
    return val

class IzhikevichBitTrueOrig:
    def __init__(self):
        self.v = -3328
        self.u = 0      
        self.FRAC = 9
        self.SCALE = 2
        self.THRESHOLD = 1536
        self.C = -3328
        self.D = 4096

    def step(self, spike_in):
        V_V = self.v * self.v
        input_term = 7680 if spike_in else 0
        dynamics = ((V_V >> (self.FRAC + self.SCALE)) + (self.v << 2) + self.v + 7168 - self.u + input_term) >> 1
        v_comb = self.v + dynamics
        u_comb = self.u + (((self.v >> 2) - self.u) >> 7)
        if v_comb >= self.THRESHOLD:
            v_ret = self.v   
            self.v = self.C
            self.u = u_comb + self.D
        else:
            self.v = v_comb
            self.u = u_comb
            v_ret = self.v
        return v_ret

class IzhikevichBitTrueTrunc:
    def __init__(self):
        self.v = -3328
        self.u = 0      
        self.FRAC = 9
        self.SCALE = 2
        self.THRESHOLD = 1536
        self.C = -3328
        self.D = 4096

    def step(self, spike_in):
        V_V = self.v * self.v
        input_term = 7680 if spike_in else 0
        sum_val = (V_V >> 11) + (to_int16(self.v << 2)) + self.v + 7168 - self.u + input_term
        dynamics = sum_val >> 1
        
        v_comb = to_int16(self.v + dynamics)
        u_comb = to_int16(self.u + (to_int16(to_int16(self.v >> 2) - self.u) >> 7))
        
        if v_comb >= self.THRESHOLD:
            v_ret = self.v   
            self.v = self.C
            self.u = to_int16(u_comb + self.D)
        else:
            self.v = v_comb
            self.u = u_comb
            v_ret = self.v
        return v_ret

orig = IzhikevichBitTrueOrig()
trunc = IzhikevichBitTrueTrunc()

for i in range(100):
    spike_in = 1 if i % 10 == 0 else 0
    o = orig.step(spike_in)
    t = trunc.step(spike_in)
    if o != t:
        print(f"Step {i}: Orig {o}, Trunc {t}")

print("Done comparing.")
