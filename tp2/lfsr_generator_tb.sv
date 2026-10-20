`default_nettype none
`timescale 1ns/1ns

module lfsr_generator_tb();

localparam N_BITS = 16;
reg random_valid;

//señales de entrada como reg y señales de salida como wire
reg clock;
reg i_reset;
reg i_valid;
reg [N_BITS-1:0] i_seed;
reg i_soft_reset;
wire [N_BITS-1:0] LFSR;


LFSR16_1002D
u_LFSR16_1002D 
(
    .clock(clock),
    .i_reset(i_reset),
    .i_valid(i_valid),
    .i_seed(i_seed),
    .i_soft_reset(i_soft_reset),
    .LFSR(LFSR)
);

`define TEST_PERIODICITY_FIXED
`define TEST_PERIODICITY_RANDOM


// Generación de clock
initial 
begin
    clock = 0;
end

always #50 clock = ~clock; // Clock de 100 ns


//valid signal
always @(posedge clock) 
begin
    if(random_valid)
    begin
        i_valid <= 1'b1;
    end
    else
    begin
        i_valid <= $urandom_range(1, 0);
    end
end


//modificamos i_seed con un valor aleatorio entre 1 y 65535
task modify_seed();
begin
    i_seed <= $urandom_range(65535, 1);
end
endtask


//set reset asincronico
task asincronous_reset();
begin
    //establezco el reset asincronico
    i_reset = 1'b1;
    //lo mantengo por un tiempo aleatorio entre 1 y 250 us
    #($urandom_range(250, 1)*1us);
    //pasado el tiempo lo desactivo
    i_reset = 1'b0;
end
endtask


//set reset sincrono
task synchronous_reset();
begin
    //establezco el reset sincrono
    @(negedge clock);
    i_soft_reset = 1'b1;
    //lo mantengo por un tiempo aleatorio entre 1 y 250 us
    #($urandom_range(250, 1)*1us);
    //pasado el tiempo lo desactivo
    i_soft_reset = 1'b0;
end
endtask


//periodicidad generador
task periodicity_test(
    output reg [N_BITS-1:0] result,
    output reg [N_BITS-1:0] seed_used
);
    reg [N_BITS-1:0] counter;
begin
    random_valid = 1'b1;

    synchronous_reset();

    seed_used = i_seed;
    
    counter = '0;

    do
    begin
        @(posedge clock);
        @(negedge clock);

        counter = counter + 1;
    end   
    while(LFSR != seed_used && counter < 2**N_BITS - 1);

    result = counter;
end
endtask


initial
begin

    reg [N_BITS-1:0] counter_value;
    reg [N_BITS-1:0] seed_used;
    integer fail_count;
    integer i;

    fail_count = 0;

    // Inicialización común (siempre corre)
    i_reset      = 1'b0;
    i_soft_reset = 1'b0;
    i_valid      = 1'b0;
    random_valid = 1'b0;
    i_seed       = 16'hFFFF;

    repeat (5) @(posedge clock);

    asincronous_reset();

    repeat (5) @(posedge clock);

    modify_seed();

    synchronous_reset();

    repeat (100) @(posedge clock);


`ifdef TEST_PERIODICITY_FIXED

    i_seed <= 16'hFFFF;

    periodicity_test(counter_value, seed_used);

    if(counter_value == 2**N_BITS - 1 && LFSR == seed_used)
    begin
        $display("TEST PASSED: fixed-seed periodicity, %0d cycles", counter_value);
    end
    else if(counter_value == 2**N_BITS - 1 && LFSR != seed_used)
    begin
        fail_count = fail_count + 1;
        $display("TEST FAILED: fixed-seed periodicity, %0d cycles", counter_value);
    end
    else if(counter_value != 2**N_BITS - 1 && LFSR == seed_used)
    begin
        fail_count = fail_count + 1;
        $display("TEST FAILED: fixed-seed periodicity, %0d cycles", counter_value);
    end

`endif


`ifdef TEST_PERIODICITY_RANDOM

    for (i = 0; i < 3; i = i + 1)
    begin

        modify_seed();

        periodicity_test(counter_value, seed_used);

        if(counter_value == 2**N_BITS - 1 && LFSR == seed_used)
        begin
            $display("TEST PASSED: iter %0d, seed %h", i, seed_used);
        end
        else if(counter_value == 2**N_BITS - 1 && LFSR != seed_used)
        begin
            fail_count = fail_count + 1;
            $display("TEST FAILED: iter %0d, seed %h, LFSR != seed_used", i, seed_used);
        end
        else if(counter_value != 2**N_BITS - 1 && LFSR == seed_used)
        begin
            fail_count = fail_count + 1;
            $display("TEST FAILED: iter %0d, seed %h", i, seed_used);
        end

    end

`endif


    if (fail_count == 0)
        $display("SUMMARY: all tests passed");
    else
        $display("SUMMARY: %0d tests failed", fail_count);

    $finish;

end

endmodule