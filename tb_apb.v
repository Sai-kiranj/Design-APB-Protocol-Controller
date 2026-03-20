`timescale 1ns/1ps
module tb_apb;
  reg        PCLK=0, PRESETn=0;
  reg [31:0] PADDR=0;
  reg        PWRITE=0;
  reg [31:0] PWDATA=0;
  reg        PSEL=0, PENABLE=0;
  reg [31:0] PRDATA1=32'hAABBCCDD;
  reg [31:0] PRDATA2=32'h11223344;
  reg [31:0] PRDATA3=32'hDEADBEEF;
  reg        PREADY1=1, PREADY2=1, PREADY3=1;
  wire       PSEL1,PSEL2,PSEL3,PENABLE_S,PWRITE_S,PREADY;
  wire[31:0] PADDR_S,PWDATA_S,PRDATA;

  apb_controller DUT (
    .PCLK(PCLK),.PRESETn(PRESETn),
    .PADDR(PADDR),.PWRITE(PWRITE),.PWDATA(PWDATA),
    .PSEL(PSEL),.PENABLE(PENABLE),
    .PSEL1(PSEL1),.PSEL2(PSEL2),.PSEL3(PSEL3),
    .PADDR_S(PADDR_S),.PWDATA_S(PWDATA_S),
    .PWRITE_S(PWRITE_S),.PENABLE_S(PENABLE_S),
    .PRDATA1(PRDATA1),.PRDATA2(PRDATA2),.PRDATA3(PRDATA3),
    .PREADY1(PREADY1),.PREADY2(PREADY2),.PREADY3(PREADY3),
    .PRDATA(PRDATA),.PREADY(PREADY)
  );

  always #5 PCLK = ~PCLK;  // 100 MHz clock

  task apb_write(input [31:0] addr, data);
    @(posedge PCLK); PADDR=addr; PWDATA=data; PWRITE=1; PSEL=1; PENABLE=0;
    @(posedge PCLK); PENABLE=1;
    @(posedge PCLK); PSEL=0; PENABLE=0; PWRITE=0;
  endtask

  task apb_read(input [31:0] addr);
    @(posedge PCLK); PADDR=addr; PWRITE=0; PSEL=1; PENABLE=0;
    @(posedge PCLK); PENABLE=1;
    @(posedge PCLK); PSEL=0; PENABLE=0;
  endtask

  initial begin
    $dumpfile("dump.vcd"); $dumpvars(0, tb_apb);
    #20 PRESETn=1;
    apb_write(32'h000, 32'hA5A5A5A5);  // Write to UART
    apb_read (32'h100);                 // Read from I2C
    apb_write(32'h200, 32'hDEAD1234);  // Write to SPI
    apb_read (32'h000);                 // Read from UART
    #50 $finish;
  end
endmodule
