<h2>PHẦN 1 : File Breakout trong framework BinsdNET</h2>

* STDP <Spike-Timing-Dependent Plasticity> : Là 1 quy tắc học tập sinh học trong mạng neuron. Nó nói rằng không chỉ việc 2 neuron bắn xung quang trọng mà còn quan trọng ai bắn trước, ai bắn sau. 

* (Bạn có thể tìm hiểu thêm tại đây : https://florian.io/papers/2007_Florian_Modulated_STDP.pdf)
  
* File "breakout.py" và file "breakout.py" đều dựa vào framework BindsNET khởi tạo mạng SNN cho game BreakoutDeterministic. 

<h3>Tuy nhiên ở file "breakout.py", phần khỏi tạo liên kết giữa các lớp :</h3>

``` python 
    inpt_middle = Connection(source=inpt, target=middle, wmin=0, wmax=1)
    python middle_out = Connection(source=middle, target=out, wmin=0, wmax=1)
```
&rarr; Không có quy tắc học (update_rule) nên các trọng số không thay đổi trong quá trình mô phỏng.

<h3>Còn ở file "breakout_stdp.py" :</h3>

``` python
    inpt_middle = Connection(source=inpt, target=middle, wmin=0, wmax=1e-1)
    middle_out = Connection(
        source=middle,
        target=out,
        wmin=0,
        wmax=1,
        update_rule=MSTDP,
        nu=1e-1,
        norm=0.5 * middle.n,
    )
```
&rarr; Có quy tắc học theo MSTDP (MTSDP là quy tắc học quy tắc học dựa vào thời gian phát xung giữa neuron tiền-synapse và hậu-synapse).

&Longrightarrow; Trọng số synapse thay đổi theo thời gian, sau nhiều vòng chơi hiệu suất được cải thiện. Việc sử dụng MSTDP đang mô phỏng mô hình Reinforcement Learning trong não bộ. 
