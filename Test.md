<h2>PHẦN 1 : File Breakout trong framework BinsdNET</h2>

*STDP <Spike-Timing-Dependent Plasticity> : -Là 1 quy tắc học tập sinh học trong mạng neuron. Nó nói rằng không chỉ việc 2 neuron bắn xung quang trọng mà còn quan trọng ai bắn trước, ai bắn sau. 

(Bạn có thể tìm hiểu thêm tại đây : https://florian.io/papers/2007_Florian_Modulated_STDP.pdf)

-File "breakout.py" và file "breakout.py" đều dựa vào framework BindsNET khởi tạo mạng SNN cho game BreakoutDeterministic. 

Tuy nhiên ở file "breakout.py", phần khỏi tạo liên kết giữa các lớp :

inpt_middle = Connection(source=inpt, target=middle, wmin=0, wmax=1)
middle_out = Connection(source=middle, target=out, wmin=0, wmax=1)



