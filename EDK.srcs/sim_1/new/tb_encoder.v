`timescale 1ns / 1ps

module tb_encoder;

reg             Bus2IP_Clk;
reg             Bus2IP_Reset;

reg  [0 : 31]   Bus2IP_Data;
reg  [0 :  3]   Bus2IP_BE;
reg  [0 :  1]   Bus2IP_RdCE;
reg  [0 :  1]   Bus2IP_WrCE;
wire [0 : 31]   IP2Bus_Data;
wire            IP2Bus_RdAck;
wire            IP2Bus_WrAck;
wire            IP2Bus_Error;

reg             encoder_a;
reg             encoder_b;
wire            irq;

encoder_user_logic dut(
   //A PLB IPIF interfész portjai.
   Bus2IP_Clk,                     //Órajel.
   Bus2IP_Reset,                   //Reset jel.
   Bus2IP_Data,                    //Írási adatbusz (IPIF -> IP).
   Bus2IP_BE,                      //Bájt engedélyezõ jelek.
   Bus2IP_RdCE,                    //Regiszter olvasás engedélyezõ jelek.
   Bus2IP_WrCE,                    //Regiszter írás engedélyezõ jelek.
   IP2Bus_Data,                    //Olvasási adatbusz (IP -> IPIF).
   IP2Bus_RdAck,                   //Regiszter olvasás nyugtázó jel.
   IP2Bus_WrAck,                   //Regiszter írás nyugtázó jel.
   IP2Bus_Error,                   //Hibajelzés az IPIF felé.
   
   //Az enkóder interfész portjai.
   encoder_a,                      //Az enkóder A jele.
   encoder_b,                      //Az enkóder B jele.
   irq                             //Megszakításkérõ kimenet.
);

task ROTATE_CLOCKWISE;
begin
encoder_a <= 1;
encoder_b <= 0;
#1_500_000 encoder_a <= 0;
#1_500_000;
end
endtask

task ROTATE_COUNTERCLOCKWISE;
begin
encoder_a <= 0;
encoder_b <= 1;
#1_500_000 encoder_b <= 0;
#1_500_000;
end
endtask

task BUS_WRITE;
input [0:31] Data;
input integer register;
begin
@ (posedge Bus2IP_Clk);
Bus2IP_Data <= Data;
Bus2IP_WrCE <= (register == 0) ? 2'b10 : 2'b01;
@ (posedge Bus2IP_Clk);
Bus2IP_Data <= 32'hZZZZZZZZ;
Bus2IP_WrCE <= 2'b00;
end
endtask

task BUS_READ_COUNTER;
begin
@ (posedge Bus2IP_Clk);
Bus2IP_RdCE <= 2'b01;
@ (posedge Bus2IP_Clk);
Bus2IP_RdCE <= 2'b00;
end
endtask

initial begin
Bus2IP_Clk <= 0;
Bus2IP_Reset <= 1;
encoder_a <= 0;
encoder_b <= 0;
Bus2IP_RdCE <= 0;

#500 Bus2IP_Reset <= 0;

#1000 BUS_WRITE({30'b0, 2'b01}, 0);

#4_000_000;
ROTATE_CLOCKWISE;
ROTATE_CLOCKWISE;
#700_000 ROTATE_CLOCKWISE;
ROTATE_COUNTERCLOCKWISE;
#400_000 ROTATE_COUNTERCLOCKWISE;
ROTATE_CLOCKWISE;

BUS_READ_COUNTER;
end

always # 10 Bus2IP_Clk <= ~Bus2IP_Clk;



endmodule
