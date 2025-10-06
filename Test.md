<h2>PHẦN 1 : File Breakout trong framework BinsdNET</h2>

* STDP <Spike-Timing-Dependent Plasticity> : Là 1 quy tắc học tập sinh học trong mạng neuron. Nó nói rằng không chỉ việc 2 neuron bắn xung quang trọng mà còn quan trọng ai bắn trước, ai bắn sau. 

  (Bạn có thể tìm hiểu thêm tại đây : https://florian.io/papers/2007_Florian_Modulated_STDP.pdf)
  
  File "breakout.py" và file "breakout.py" đều dựa vào framework BindsNET khởi tạo mạng SNN cho game BreakoutDeterministic. 

<h3>Tuy nhiên ở file "breakout.py", phần khỏi tạo liên kết giữa các lớp :</h3>

``` python 
    inpt_middle = Connection(source=inpt, target=middle, wmin=0, wmax=1)
    python middle_out = Connection(source=middle, target=out, wmin=0, wmax=1)
```
  Hai Connection này chỉ khởi tạo trọng số tĩnh (fixed weights).

  Các tham số wmin và wmax quy định giới hạn giá trị của trọng số (từ 0 → 1).

  Không có quy tắc học (update_rule) nên các trọng số không thay đổi trong quá trình mô phỏng.

  Nói cách khác: mạng này chỉ truyền tín hiệu, không học.   
