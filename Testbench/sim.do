vlib work
vmap work work

# Biên dịch các module cần thiết
vlog -work work src/mul16s_HF7.v.v
vlog -work work src/neuron_model.v
vlog -work work tb_neuron.v

# Bắt đầu mô phỏng
vsim -voptargs=+acc work.tb_neuron

# Thêm tất cả các tín hiệu vào sóng (wave)
add wave -position insertpoint sim:/tb_neuron/*
add wave -position insertpoint sim:/tb_neuron/uut/*

# Chạy mô phỏng
run -all
