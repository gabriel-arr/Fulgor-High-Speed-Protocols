`default_nettype none
`timescale 1ns/1ns

module lfsr_generator_tb();
    //señales de entrada como reg y señales de salida como wire
    reg clock;
    reg i_reset;
    reg i_valid;
    reg [15:0] i_seed;
    reg i_soft_reset;
    wire [15:0] LFSR;

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

    // Generación de clock
    initial 
    begin
        clock = 0;
    end
    always #50 clock = ~clock; // Clock de 100 ns

    //valid signal
    task valid_signal();
    begin
        i_valid = 1'b0;
        
        if($urandom_range(0, 1))
        begin
            @(posedge clock);
            i_valid = 1'b1;
        end
    end
    endtask

    //modificamos i_seed
    task modify_seed();
    begin
        i_seed = $urandom_range(65535, 1);
    end
    endtask
    
    //set reset asincronico
    task asincronous_reset();
    time reset_time;
    begin
        //establezco el reset asincronico
        //@(posedge clock);
        i_reset = 1'b1;
        //lo mantengo por un tiempo aleatorio entre 1 y 100 ciclos de clock
        #($urandom_range(1, 100)*1us);
        //pasado el tiempo lo desactivo
        i_reset = 1'b0;
    end
    endtask


    //set reset sincrono
    task synchronous_reset();
        time reset_time;
    begin
        //establezco el reset sincrono
        @(negedge clock);
        i_soft_reset = 1'b1;
        //lo mantengo por un tiempo aleatorio entre 1 y 100 ciclos de clock
        #($urandom_range(1, 100)*1us);
        //pasado el tiempo lo desactivo
        i_soft_reset = 1'b0;
    end
    endtask
endmodule