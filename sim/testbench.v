
`timescale 1ns / 1ps



module tb();
reg sys_clk=1'b0,tx_enable,rst,even_odd;
reg[7:0] tx_data;
wire [7:0]parallel_data_out;
wire serial_out,busy_tx,busy_rx,data_valid;

UART dut(sys_clk,rst,tx_enable,even_odd,tx_data,
             parallel_data_out, busy_tx,busy_rx,data_valid);
localparam  half_period=7.8125;


always #half_period sys_clk=~sys_clk;

integer i=0;
 initial 
begin
#0;
rst=1'b0;
tx_enable=1'b0;
even_odd=1'b0;
for(i = 0; i < 10; i = i + 1) begin
#6000
tx_data = $urandom_range(10 , 200);
tx_enable=1'b0;
tx_enable=1'b1;
rst=1'b0;

end
$stop; 
end
 
