// apb_controller.v — 1 Master, 3 Slaves (UART, I2C, SPI)
module apb_controller (
  input  wire        PCLK, PRESETn,
  // From master
  input  wire [31:0] PADDR,
  input  wire        PWRITE,
  input  wire [31:0] PWDATA,
  input  wire        PSEL,
  input  wire        PENABLE,
  // To slaves
  output reg         PSEL1, PSEL2, PSEL3,
  output reg  [31:0] PADDR_S, PWDATA_S,
  output reg         PWRITE_S, PENABLE_S,
  // From slaves
  input  wire [31:0] PRDATA1, PRDATA2, PRDATA3,
  input  wire        PREADY1, PREADY2, PREADY3,
  // To master
  output reg  [31:0] PRDATA,
  output reg         PREADY
);

  // FSM states
  localparam IDLE   = 2'b00;
  localparam SETUP  = 2'b01;
  localparam ENABLE = 2'b10;

  reg [1:0] state;

  // Address decode: 0x000–0x0FF → UART, 0x100–0x1FF → I2C, 0x200–0x2FF → SPI
  wire sel1 = (PADDR[11:8] == 4'h0);
  wire sel2 = (PADDR[11:8] == 4'h1);
  wire sel3 = (PADDR[11:8] == 4'h2);

  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      state <= IDLE;
      {PSEL1,PSEL2,PSEL3,PENABLE_S,PREADY} <= 0;
    end else begin
      case (state)
        IDLE: begin
          PSEL1<=0; PSEL2<=0; PSEL3<=0; PENABLE_S<=0;
          if (PSEL) begin
            PADDR_S  <= PADDR;
            PWDATA_S <= PWDATA;
            PWRITE_S <= PWRITE;
            PSEL1 <= sel1; PSEL2 <= sel2; PSEL3 <= sel3;
            state <= SETUP;
          end
        end
        SETUP: begin
          PENABLE_S <= 1;
          state <= ENABLE;
        end
        ENABLE: begin
          if ((PSEL1 & PREADY1) | (PSEL2 & PREADY2) | (PSEL3 & PREADY3)) begin
            PREADY <= 1;
            PRDATA <= PSEL1 ? PRDATA1 : PSEL2 ? PRDATA2 : PRDATA3;
            PENABLE_S <= 0;
            PSEL1<=0; PSEL2<=0; PSEL3<=0;
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule
