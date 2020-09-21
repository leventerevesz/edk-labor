`timescale 1ns / 1ps

module tb_encoder;

reg clk;
reg rst;

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
   .encoder_a (1'b0),                      //Az enkóder A jele.
   .encoder_b (1'b0),                      //Az enkóder B jele.
   .irq ()
);

initial begin
clk <= 0;
rst <= 1;

#500 rst <= 0;
end

always # 10 clk <= ~clk;

endmodule
