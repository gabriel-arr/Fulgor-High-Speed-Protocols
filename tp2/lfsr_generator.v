module LFSR16_1002D #(
  parameter DEFAULT_SEED = 16'hFFFF,
  parameter N_BITS = 16
)(
  input clock,
  input i_reset,
  input i_valid,
  input [N_BITS-1:0] i_seed,
  input i_soft_reset,
  output reg [N_BITS-1:0] LFSR
);

wire feedback = LFSR[N_BITS-1];

always @(posedge clock or posedge i_reset)
begin
  if (i_reset)
    LFSR <= DEFAULT_SEED;
  else if (i_soft_reset)
    LFSR <= i_seed;
  else if (i_valid)
  begin
    LFSR[0] <= feedback;
    LFSR[1] <= LFSR[0];
    LFSR[2] <= LFSR[1] ^ feedback;
    LFSR[3] <= LFSR[2] ^ feedback;
    LFSR[4] <= LFSR[3];
    LFSR[5] <= LFSR[4] ^ feedback;
    LFSR[6] <= LFSR[5];
    LFSR[7] <= LFSR[6];
    LFSR[8] <= LFSR[7];
    LFSR[9] <= LFSR[8];
    LFSR[10] <= LFSR[9];
    LFSR[11] <= LFSR[10];
    LFSR[12] <= LFSR[11];
    LFSR[13] <= LFSR[12];
    LFSR[14] <= LFSR[13];
    LFSR[15] <= LFSR[14];
  end
  
end
endmodule
    