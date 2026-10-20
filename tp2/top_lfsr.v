`default_nettype none

module lfsr_top #(
    parameter N_BITS = 16
)(
    input  wire                  clock,
    input  wire                  i_reset_generator,
    input  wire                  i_reset_checker,

    input  wire                  i_valid,
    input  wire [N_BITS-1:0]     i_seed,
    input  wire                  i_soft_reset,

    input  wire                  i_inject_error,

    output wire [N_BITS-1:0]     o_lfsr,
    output wire                  o_lock
);

wire [N_BITS-1:0] LFSR;
wire [N_BITS-1:0] checker_data;


// GENERATOR
LFSR16_1002D
u_LFSR16_1002D
(
    .clock(clock),
    .i_reset(i_reset_generator),
    .i_valid(i_valid),
    .i_seed(i_seed),
    .i_soft_reset(i_soft_reset),
    .LFSR(LFSR)
);


// Inyección de error para probar el checker
assign checker_data = i_inject_error ?
                      (LFSR ^ 16'h0001) :
                       LFSR;


// CHECKER
lfsr_checker
u_lfsr_checker
(
    .clock(clock),
    .i_reset(i_reset_checker),
    .i_valid(i_valid),
    .i_data(checker_data),
    .o_lock(o_lock)
);


// Salida opcional para observar el LFSR desde el TB
assign o_lfsr = LFSR;

endmodule

`default_nettype wire