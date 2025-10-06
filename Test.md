<h2>PHẦN 1 : File Breakout trong framework BinsdNET</h2>

<h3>STDP <Spike-Timing-Dependent Plasticity> : Là 1 quy tắc học tập sinh học trong mạng neuron. Nó nói rằng không chỉ việc 2 neuron bắn xung quang trọng mà còn quan trọng ai bắn trước, ai bắn sau.</h3>

* (Bạn có thể tìm hiểu thêm tại đây : https://florian.io/papers/2007_Florian_Modulated_STDP.pdf)
  
* File "breakout.py" và file "breakout.py" đều dựa vào framework BindsNET khởi tạo mạng SNN cho game BreakoutDeterministic. 

<h3>Tuy nhiên ở file "breakout.py", phần khỏi tạo liên kết giữa các lớp :</h3>

``` python 
    inpt_middle = Connection(source=inpt, target=middle, wmin=0, wmax=1)
    python middle_out = Connection(source=middle, target=out, wmin=0, wmax=1)
```
&rarr; Không có quy tắc học (update_rule) cụ thể nên các trọng số không thay đổi trong quá trình mô phỏng.

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

<h4>&Longrightarrow; Trọng số synapse thay đổi theo thời gian, sau nhiều vòng chơi hiệu suất được cải thiện. Việc sử dụng MSTDP đang mô phỏng mô hình Reinforcement Learning 1 cách sinh học trong não bộ.</h4>


<h3>Pipeline BindsNET : Là khung cho việc mô phỏng và huấn luyện mạng SNN của BinsdNET</h3>

``` python
environment_pipeline = EnvironmentPipeline(
    network,
    environment,
    encoding=bernoulli,
    action_function=select_softmax,
    output="Output Layer",
)
```
* network : Mạng đã xây dựng.
* environment : Môi trường trò chơi.
* encoding : Mã hóa dữ liệu đầu vào theo phân phối chuẩn Bernoulli.
* action_functionn : Chọn một hành động bằng cách sử dụng hàm softmax dựa trên số lượng spike (xung) phát ra từ một lớp trong mạng.

<h2>Phần 2 : Izhikevich Verilog</h2>

<h3> Design Code </h3>
```verilog 

    module Izhikevich (
	    input clk,
	    input rst,
	    input signed [15:0] I_in,   			   // Input current
	    output reg signed [15:0] V, 			   // Membrane potential
	    output reg flag                            // Save the spike
    );

	    parameter signed [15:0] a = 16'sd2;   		// Recovery time scale 
	    parameter signed [15:0] b = 16'sd2;   		// Sensitivity of u
	    parameter signed [15:0] c = -16'sd65; 		// Reset value for v
	    parameter signed [15:0] d = 16'sd8;   		// Reset increment for u
	    parameter signed [15:0] V_peak = 16'sd30;		//Threshold
	
	    reg signed [15:0] u; 				// Recovery variable
	
	    always @(posedge clk or posedge rst) begin
	        if (rst) begin
		    flag <= 1'b0;
	            V <= -16'sd70; 
	            u <= 16'sd0;   
	        end 
		else begin
	            if (V >= V_peak) begin
			flag <= 1'b1;
	                V <= c;          
	                u <= u + d;         
	            end 
		    else begin
	                flag <= 1'b0;
	                V <= V + ((16'sd4 / 16'sd100) * V * V) + 16'sd5 * V + 16'sd140 - u + I_in;
	                u <= u + (a / 16'sd100) * ((b / 16'sd10) * V - u);
	            end
	        end
	    end
		
	endmodule
```
