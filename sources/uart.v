
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT jammu
// Engineer: vedhant abrol
// 
// Create Date: 14.06.2024 10:04:27
// Design Name: UART
// Module Name: UART
// Project Name: high speed UART
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// baud_clk_generator

module baud_rate_generator(input sys_clk, rst, output reg baud_clk);
parameter sys_clk_freq = 64000000;
parameter baud_rate = 4000000;
parameter count= sys_clk_freq/baud_rate;
parameter idle=0;
integer temp=0;
initial begin
baud_clk=idle;
end
always @(posedge sys_clk)begin
if(rst)begin
temp<=0;
baud_clk<=idle;
end
else begin
if(temp==(count-1))begin
 baud_clk <= ~baud_clk;
temp<=0;
end
else begin
baud_clk<=baud_clk;
temp<=temp+1;
end
end
end
endmodule

//parity generator module

module parity(input even_odd,input [7:0] tx_data,output reg parity_bit);

integer i;
reg temp_parity;
always@(*)begin
temp_parity=tx_data[0];
for(i=0;i<8;i=i+1)begin
temp_parity=tx_data[i]^temp_parity;
end
if(even_odd) parity_bit= ~temp_parity;
else parity_bit = temp_parity;
end

endmodule

//Transmitter module

module tx_FSM(input baud_clk,rst,tx_enable,output reg busy,load,shift);
 parameter s_idle=0;
 parameter s_load=1;
 parameter s_shift=2;
 parameter s_wait=3;
 reg [1:0] state=s_idle, nx_state=s_idle;
// integer count=0;
// delay logic
integer count=0;

always @(posedge baud_clk)begin
if(rst) count=0;
else begin

 if(shift==0) count=0;
else if(count==11) count=0;
else if(shift) count =count+1;
else count=0;
end
end
 //reset_logic_of_FSM
 always @(posedge baud_clk)begin
 if(rst) state<=s_idle;
 else    state<=nx_state;
 end 
 //Output_logic_of_FSM
always@(tx_enable,state)begin
case(state)

s_idle : begin
load<=0;
busy<=0;
shift<=0;
end

s_load : begin
load<=1;
busy<=1;
shift<=0;
end

s_shift : begin
load<=0;
busy<=1;
shift<=1;
end

s_wait : begin
load<=0;
busy<=1;
shift<=0;
end
endcase
end
//nx_state logic
always @(state,tx_enable,count)begin

case(state)
s_idle: begin
if(tx_enable) nx_state<=s_load;
else nx_state<=s_idle;
end

s_load: begin
nx_state<=s_shift;
end
s_shift: begin
if(count==11) nx_state<=s_wait;
else nx_state<=s_shift;
end 
s_wait: begin
 nx_state<=s_idle;

end
endcase
end

endmodule

// PISO module

module PISO(input load,shift,parity_bit,rst,baud_clk,input [7:0]tx_data,output reg serial_out);
reg [10:0]PISO;
integer count=10;
//always@(posedge baud_clk)begin
//if(count==10) count=0;
//else count=count+1;
//end
always@(posedge baud_clk)begin
if(rst)begin 
PISO=11'b0;count=0 ;
serial_out=1'b1;
end
else if(load)begin
PISO={1'b0,tx_data,1'b1,parity_bit};
end
else if(shift)begin
serial_out = PISO[count];
count=count-1;
end
else begin
count=10;
serial_out=1'b1;
end
end
endmodule

//transmitter
module transmitter(input sys_clk,rst,tx_enable,even_odd,[7:0]tx_data,output  busy,serial_out);
wire baud_clk,parity_bit,load,shift,busy_t;
baud_rate_generator baud_generator(sys_clk,rst,baud_clk);
parity parity_generator(even_odd,tx_data,parity_bit);
tx_FSM transmitter_FSM(baud_clk,rst,tx_enable,busy_t,load,shift);
PISO PISO_regester(load,shift,parity_bit,rst,baud_clk,tx_data,serial_out);
assign busy=busy_t;
endmodule

//Receiving end
module dff(input d,baud_clk,rst,output reg q);
always @(posedge baud_clk)begin
if(rst)begin
q<=1'b0;
end
else begin
q<=d;
end
end
endmodule
module neg_edge(input baud_clk,serial_in,rst,output  det_edge);
wire q,d_not;
dff df(serial_in,baud_clk,rst,q);
assign d_not=~serial_in;
assign det_edge= q& d_not;

endmodule
// reciever_FSM
module receiver_FSM(input baud_clk,rst,det_edge,output reg load,shift,busy);
parameter s_idle=0,s_shift=1,s_load=2,s_wait=3;
reg [1:0] state=s_idle,nx_state=s_idle;
//reset logic
always @(posedge baud_clk)begin
if(rst)begin
state<=s_idle;
end
else begin
state<=nx_state;
end
end
//delay add
integer count=0;
always @(posedge baud_clk)begin
if(rst) count=0;
else begin
 if(shift==0) count=0;
else if(count==11) count=0;
else if(shift) count =count+1;
else count=0;
end
end

// output logic
always @(det_edge,state)begin
case(state)

s_idle: begin
load<=1'b0;
shift<=1'b0;
busy<=1'b0;
end

s_shift: begin
load<=1'b0;
shift<=1'b1;
busy<=1'b1;
end

s_load: begin
load<=1'b1;
shift<=1'b0;
busy<=1'b1;
end

s_wait: begin
load<=1'b0;
shift<=1'b0;
busy<=1'b1;
end
endcase
end
// nx_state logic
always @(state,count,det_edge,count)begin
case(state)

s_idle: begin
if(det_edge)begin
nx_state<=s_shift;
end
else begin
nx_state<=s_idle;
end
end

s_shift: begin
if(count==11) nx_state<=s_load;
else nx_state<=s_shift;
end

s_load: begin
 nx_state<=s_wait;
end

s_wait: begin
 nx_state<=s_idle;
end
endcase
end
endmodule

//SIPO register
module SIPO(input baud_clk,rst,load,shift,serial_in,output reg[7:0]parallel_out);

reg [9:0]SIPO;
integer count=0;
always @(posedge baud_clk)begin
if(rst)begin
SIPO=11'b0;
count=0;
parallel_out=8'b0;
end
else if(shift)begin

SIPO[count]=serial_in;
count=count+1;
end
else if(load)begin
parallel_out <= {SIPO[0], SIPO[1], SIPO[2], SIPO[3], SIPO[4], SIPO[5], SIPO[6], SIPO[7]};
count=0;
end
else begin
count=0;
end

end
endmodule
// parity checker
module parity_checker(input [7:0] parallel_data,output reg data_valid);
integer i;
reg temp_parity;
always@(*)begin
temp_parity=parallel_data[0];
for(i=0;i<8;i=i+1)begin
temp_parity=parallel_data[i]^temp_parity;
end
if(1'b1==~temp_parity) data_valid=1'b1;
else data_valid=1'b0;
end

endmodule
// receiver module
module receiver(input sys_clk,rst,serial_in,output  [7:0]parallel_data,output  data_valid,busy_rx);
wire baud_clk,det_edge,load,shift,busy;
wire [7:0]parallel_data_rx;
baud_rate_generator baud_generator(sys_clk,rst,baud_clk);
neg_edge negative_edge_detector(baud_clk,serial_in,rst,det_edge);
receiver_FSM receiverFSM(baud_clk,rst,det_edge,load,shift,busy);
SIPO SIPO_register(baud_clk,rst,load,shift,serial_in,parallel_data_rx);
parity_checker parityChecker(parallel_data_rx,data_valid);
assign busy_rx=busy;
assign parallel_data=parallel_data_rx;
endmodule

module UART(input sys_clk,rst,tx_enable,even_odd,input [7:0]tx_data_in,
            output[7:0] parallel_data_out,output busy_tx,busy_rx,data_valid);
wire busy_t,busy_r,serial_out;
transmitter transmitter_module(sys_clk,rst,tx_enable,even_odd,tx_data_in,busy_t,serial_out);
receiver receiver_module(sys_clk,rst,serial_out,parallel_data_out,data_valid,busy_r);  
assign busy_tx=busy_t;
assign busy_rx=busy_r;       
endmodule
