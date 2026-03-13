// TDP BRAM Infer

module rams_tdp_rf_rf (
input logic clka,
input logic clkb,

input logic ena,
input logic enb,
input logic wea,
input logic web,

input logic [9:0] addra,
input logic [9:0] addrb,

input logic [15:0] dia,
input logic [15:0] dib,
input logic [15:0] doa,
input logic [15:0] dob);

logic [15:0] ram [1023:0];
logic [15:0] doa,dob;

always_ff @(posedge clka)
begin 
  if (ena)
    begin
      if (wea)
        ram[addra] <= dia;
      doa <= ram[addra];
    end
end

always_ff @(posedge clkb) 
begin 
  if (enb)
    begin
      if (web)
        ram[addrb] <= dib;
      dob <= ram[addrb];
    end
end

endmodule
