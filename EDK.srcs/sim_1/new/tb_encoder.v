`timescale 1ns / 1ps

module tb_encoder;

reg clk;
reg rst;
reg A, B;

encoder_user_logic dut(
   .Bus2IP_Clk (clk),                     //Órajel.
   .Bus2IP_Reset (rst),                   //Reset jel.
   .Bus2IP_Data (),                    //Írási adatbusz (IPIF -> IP).
   .Bus2IP_BE (),                      //Bájt engedélyezõ jelek.
   .Bus2IP_RdCE (),                    //Regiszter olvasás engedélyezõ jelek.
   .Bus2IP_WrCE (),                    //Regiszter írás engedélyezõ jelek.
   .IP2Bus_Data (),                    //Olvasási adatbusz (IP -> IPIF).
   .IP2Bus_RdAck (),                   //Regiszter olvasás nyugtázó jel.
   .IP2Bus_WrAck (),                   //Regiszter írás nyugtázó jel.
   .IP2Bus_Error (),                   //Hibajelzés az IPIF felé.
   
   //Az enkóder interfész portjai.
   .encoder_a (A),                      //Az enkóder A jele.
   .encoder_b (B),                      //Az enkóder B jele.
   .irq ()
);

task ROTATE_CLOCKWISE;
begin
A <= 1;
B <= 0;
#1_500_000 A <= 0;
#1_500_000;
end
endtask

task ROTATE_COUNTERCLOCKWISE;
begin
A <= 0;
B <= 1;
#1_500_000 B <= 0;
#1_500_000;
end
endtask

initial begin
clk <= 0;
rst <= 1;
A <= 0;
B <= 0;

#500 rst <= 0;

#4_000_000;
ROTATE_CLOCKWISE;
ROTATE_CLOCKWISE;
#700_000 ROTATE_CLOCKWISE;
ROTATE_COUNTERCLOCKWISE;
#400_000 ROTATE_COUNTERCLOCKWISE;
ROTATE_CLOCKWISE;
end

always # 10 clk <= ~clk;



endmodule
