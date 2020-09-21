//*****************************************************************************
//* LCD interfész modul.                                                      *
//* Rendszerarchitektúrák labor, 2. EDK-s mérés.                              *
//*****************************************************************************
module lcd_user_logic(
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
   
   //Az LCD interfész portjai.
   lcd
);

//*****************************************************************************
//* A PLB IPIF interfész paraméterei (EZEKET NE MÓDOSÍTSA!).                  *
//*****************************************************************************
parameter C_SLV_DWIDTH = 32;
parameter C_NUM_REG    = 1;


//*****************************************************************************
//* A PLB IPIF interfész portjainak definiálása (EZEKET NE MÓDOSÍTSA!).       *
//*****************************************************************************
input  wire                        Bus2IP_Clk;
input  wire                        Bus2IP_Reset;
input  wire [0 : C_SLV_DWIDTH-1]   Bus2IP_Data;
input  wire [0 : C_SLV_DWIDTH/8-1] Bus2IP_BE;
input  wire [0 : C_NUM_REG-1]      Bus2IP_RdCE;
input  wire [0 : C_NUM_REG-1]      Bus2IP_WrCE;
output reg  [0 : C_SLV_DWIDTH-1]   IP2Bus_Data;
output wire                        IP2Bus_RdAck;
output wire                        IP2Bus_WrAck;
output wire                        IP2Bus_Error;


//*****************************************************************************
//* Az LCD interfész portjainak definiálása (EZEKET NE MÓDOSÍTSA!).           *
//*****************************************************************************
output reg  [6:0]                  lcd;


//*****************************************************************************
//* Az írási adatbusz bitjeinek megfordítása.                                 *
//* A továbbiakban a Bus2IP_Data jel helyett használja a wr_data jelet.       *
//*****************************************************************************
reg     [C_SLV_DWIDTH-1:0] wr_data;
reg     [C_SLV_DWIDTH-1:0] rd_data;
integer                    i;

always @(*)
   for (i = 0; i < C_SLV_DWIDTH; i = i + 1)
   begin
      wr_data[i] <= Bus2IP_Data[C_SLV_DWIDTH-i-1];
      IP2Bus_Data[i] <= rd_data[C_SLV_DWIDTH-i-1];
   end
      

//*****************************************************************************
//* A nyugtázó- és hibajelek meghajtása.                                      *
//*****************************************************************************
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_Error = 1'b0;


//*****************************************************************************
//* LCD adatregiszter (BÁZIS+0x00).                                           *
//*****************************************************************************
always @ (posedge Bus2IP_Clk)
if (Bus2IP_WrCE[0])
    lcd <= wr_data[6:0];

//*****************************************************************************
//* Az olvasási adatbusz meghajtása.                                          *
//*****************************************************************************
always @ ( * )
if (Bus2IP_RdCE[0])
    rd_data <= {25'b0, lcd};
else
    rd_data <= 32'b0;

endmodule