//*****************************************************************************
//* Enkóder interfész modul.                                                  *
//* Rendszerarchitektúrák labor, 2. EDK-s mérés.                              *
//*****************************************************************************
module encoder_user_logic(
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

//*****************************************************************************
//* A PLB IPIF interfész paraméterei (EZEKET NE MÓDOSÍTSA!).                  *
//*****************************************************************************
parameter C_SLV_DWIDTH = 32;
parameter C_NUM_REG    = 2;


//*****************************************************************************
//* A PLB IPIF interfész portjainak definiálása (EZEKET NE MÓDOSÍTSA!).       *
//*****************************************************************************
input  wire                        Bus2IP_Clk;
input  wire                        Bus2IP_Reset;
input  wire [C_SLV_DWIDTH-1 : 0]   Bus2IP_Data;
input  wire [C_SLV_DWIDTH/8-1 : 0] Bus2IP_BE;
input  wire [C_NUM_REG-1 : 0]      Bus2IP_RdCE;
input  wire [C_NUM_REG-1 : 0]      Bus2IP_WrCE;
output reg  [C_SLV_DWIDTH-1 : 0]   IP2Bus_Data;
output wire                        IP2Bus_RdAck;
output wire                        IP2Bus_WrAck;
output wire                        IP2Bus_Error;


//*****************************************************************************
//* Az enkóder interfész portjainak definiálása (EZEKET NE MÓDOSÍTSA!).       *
//*****************************************************************************
input  wire                        encoder_a;
input  wire                        encoder_b;
output wire                        irq;


//*****************************************************************************
//* Az írási adatbusz bitjeinek megfordítása.                                 *
//* A továbbiakban a Bus2IP_Data jel helyett használja a wr_data jelet.       *
//*****************************************************************************
reg     [C_SLV_DWIDTH-1:0] wr_data;
integer                    i;

always @(*)
   for (i = 0; i < C_SLV_DWIDTH; i = i + 1)
      wr_data[i] <= Bus2IP_Data[C_SLV_DWIDTH-i-1];
      

//*****************************************************************************
//* A nyugtázó- és hibajelek meghajtása.                                      *
//*****************************************************************************
assign IP2Bus_WrAck = |Bus2IP_WrCE;
assign IP2Bus_RdAck = |Bus2IP_RdCE;
assign IP2Bus_Error = 1'b0;


//*****************************************************************************
//* Az enkóder jeleinek mintavételezése 1 kHz-el és az események dekódolása.  *
//*****************************************************************************

// Mintavételező órajel
reg [15:0] clk_counter;

always @ (posedge Bus2IP_Clk)
if (clk_counter == 16'b0 || Bus2IP_Reset)
    clk_counter <= 16'd49999;
else
    clk_counter <= clk_counter - 1;
    
wire sample_clk = (clk_counter == 16'b0);


// Shift regiszterek
reg shr_a;
reg shr_b;

always @ (posedge Bus2IP_Clk)
if (sample_clk == 1'b1)
begin
    shr_a = encoder_a;
    shr_b = encoder_b;
end

wire [1:0] edge_a = {shr_a, encoder_a};
wire [1:0] edge_b = {shr_b, encoder_b};

wire signal_counter_up = (edge_a == 1'b01 && edge_b == 2'b00 && sample_clk);
wire signal_counter_down = (edge_a == 2'b00 && edge_b == 2'b01 && sample_clk);


//*****************************************************************************
//* Számláló (BÁZIS+0x04).                                                    *
//*****************************************************************************
reg signed [7:0] counter;

always @ (posedge Bus2IP_Clk)
if (Bus2IP_Reset)
    counter <= 0;
// Ha épp olvasás történik
else if (Bus2IP_RdCE[1] == 1) begin
    if (signal_counter_up)
        counter <= 1;
    else if (signal_counter_down)
        counter <= 8'b1111_1111;
    else
        counter <= 0;
end
else begin
    if (signal_counter_up)
        counter <= counter + 1;
    else if (signal_counter_down)
        counter <= counter - 1;
end


//*****************************************************************************
//* Vezérlõ/státusz regiszter (BÁZIS+0x00).                                   *
//* A megszakításkérõ jel elõállítása.                                        *
//*****************************************************************************
reg ie;
reg iflag;

always @ (posedge Bus2IP_Clk)
   if (Bus2IP_WrCE[0]) begin
      ie <= wr_data[0];
      iflag <= wr_data[1];
   end

always @ (posedge Bus2IP_Clk)
    if (counter != 0)
        iflag <= 1'b1;

assign irq = ie && iflag;


//*****************************************************************************
//* Az olvasási adatbusz meghajtása.                                          *
//*****************************************************************************

always @ (posedge Bus2IP_Clk)
if (Bus2IP_RdCE[0])
    IP2Bus_Data <= {30'b0, iflag, ie};
else if (Bus2IP_RdCE[1]) begin
    IP2Bus_Data <= {24'b0, counter};
    iflag <= 1'b0;
end
else
    IP2Bus_Data <= 32'b0;

endmodule