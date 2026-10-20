`default_nettype none
`timescale 1ns/1ns

module lfsr_checker_tb();

localparam N_BITS = 16;
localparam integer LFSR_PERIOD = (1 << N_BITS) - 1;
integer random_wait;


// Entradas controladas por el TB
reg                 clock;
reg                 reset_generator;
reg                 reset_checker;
reg                 i_valid;
reg [N_BITS-1:0]    i_seed;
reg                 i_soft_reset;
reg                 inject_error;

// Conexiones entre módulos
wire [N_BITS-1:0]   LFSR;
wire                o_lock;



lfsr_top
u_lfsr_top
(
    .clock(clock),

    .i_reset_generator(reset_generator),
    .i_reset_checker(reset_checker),

    .i_valid(i_valid),
    .i_seed(i_seed),
    .i_soft_reset(i_soft_reset),

    .i_inject_error(inject_error),

    .o_lfsr(LFSR),
    .o_lock(o_lock)
);

//clock
initial
begin
    clock = 1'b0;
end

always #50 clock = ~clock;

//monitor de lock
always @(o_lock)
begin
    if (o_lock)
        $display("[%0t ns] Checker -> LOCKED", $time);
    else
        $display("[%0t ns] Checker -> UNLOCKED", $time);
end

`define TEST_1
//`define TEST_2
//`define TEST_3
//`define TEST_4
//`define TEST_5

//tests
`ifdef TEST_1

initial
begin
    $display("========== TEST 1 ==========");

    // Inicializacion
    reset_generator = 1'b1;
    reset_checker   = 1'b1;
    i_valid         = 1'b0;
    i_seed          = 16'hFFFF;
    i_soft_reset    = 1'b0;
    inject_error    = 1'b0;

    #200;

    // Salimos de reset
    reset_generator = 1'b0;
    reset_checker   = 1'b0;

    // Trafico valido
    i_valid = 1'b1;

    // 1 dato para sincronizar + 5 correctos para hacer LOCK
    repeat(6)
        @(posedge clock);

    // Esperamos a que se actualicen las asignaciones
    @(negedge clock);

    if (o_lock !== 1'b1)
    begin
        $display("TEST 1 FAIL: el checker no hizo LOCK");
        $finish;
    end

    $display("Checker hizo LOCK correctamente");

    // Verificar que permanece LOCKED durante un periodo completo
    for (integer i = 0; i < LFSR_PERIOD; i = i + 1)
    begin
        @(negedge clock);

        if (o_lock !== 1'b1)
        begin
            $display("TEST 1 FAIL: perdio LOCK en el ciclo %0d", i);
            $finish;
        end
    end

    $display("TEST 1 PASS: permanecio LOCKED durante %0d ciclos",
             LFSR_PERIOD);

    $finish;
end

`endif

`ifdef TEST_2

initial
begin
    $display("========== TEST 2 ==========");

    // Inicializacion
    reset_generator = 1'b1;
    reset_checker   = 1'b1;
    i_valid         = 1'b0;
    i_seed          = 16'hFFFF;
    i_soft_reset    = 1'b0;
    inject_error    = 1'b0;

    #200;

    // Salimos de reset
    reset_generator = 1'b0;
    reset_checker   = 1'b0;

    i_valid = 1'b1;

    // 1 dato para sincronizar + 4 datos correctos
    repeat(5)
        @(negedge clock);

    // Todavia NO debe haber LOCK
    if (o_lock !== 1'b0)
    begin
        $display("TEST 2 FAIL: hizo LOCK antes de los 5 datos correctos");
        $finish;
    end

    // Inyectamos 1 dato incorrecto
    inject_error = 1'b1;

    // Esperamos que el checker lo procese
    @(negedge clock);

    if (o_lock !== 1'b0)
    begin
        $display("TEST 2 FAIL: hizo LOCK con 4 correctos + 1 incorrecto");
        $finish;
    end

    // Volvemos a trafico normal
    inject_error = 1'b0;

    $display("TEST 2 PASS: 4 correctos + 1 incorrecto no generan LOCK");

    $finish;
end

`endif

`ifdef TEST_3

initial
begin
    $display("========== TEST 3 ==========");

    // Inicializacion
    reset_generator = 1'b1;
    reset_checker   = 1'b1;
    i_valid         = 1'b0;
    i_seed          = 16'hFFFF;
    i_soft_reset    = 1'b0;
    inject_error    = 1'b0;

    #200;

    // Salimos de reset
    reset_generator = 1'b0;
    reset_checker   = 1'b0;

    i_valid = 1'b1;

    // 1 dato para sincronizar + 5 correctos para hacer LOCK
    repeat(6)
        @(posedge clock);

    @(negedge clock);

    // Verificamos que primero haya hecho LOCK
    if (o_lock !== 1'b1)
    begin
        $display("TEST 3 FAIL: el checker no hizo LOCK inicialmente");
        $finish;
    end

    $display("Checker inicialmente LOCKED");

    // Primer dato incorrecto
    inject_error = 1'b1;
    @(negedge clock);

    if (o_lock !== 1'b1)
    begin
        $display("TEST 3 FAIL: hizo UNLOCK con 1 dato incorrecto");
        $finish;
    end

    // Segundo dato incorrecto
    @(negedge clock);

    if (o_lock !== 1'b1)
    begin
        $display("TEST 3 FAIL: hizo UNLOCK con 2 datos incorrectos");
        $finish;
    end

    // Ahora enviamos un dato correcto
    inject_error = 1'b0;
    @(negedge clock);

    if (o_lock !== 1'b1)
    begin
        $display("TEST 3 FAIL: hizo UNLOCK con 2 incorrectos + 1 correcto");
        $finish;
    end

    $display("TEST 3 PASS: permanecio LOCKED con 2 incorrectos + 1 correcto");

    $finish;
end

`endif

`ifdef TEST_4

initial
begin
    $display("========== TEST 4 ==========");

    // Inicializacion
    reset_generator = 1'b1;
    reset_checker   = 1'b1;
    i_valid         = 1'b0;
    i_seed          = 16'hFFFF;
    i_soft_reset    = 1'b0;
    inject_error    = 1'b0;

    #200;

    // Salimos de reset
    reset_generator = 1'b0;
    reset_checker   = 1'b0;

    i_valid = 1'b1;

    // 1 dato para sincronizar + 5 correctos
    repeat(6)
        @(posedge clock);

    @(negedge clock);

    // Debe haber hecho LOCK
    if (o_lock !== 1'b1)
    begin
        $display("TEST 4 FAIL: no hizo LOCK despues de 5 datos correctos");
        $finish;
    end

    $display("Checker hizo LOCK correctamente");

    // Inyectamos 3 datos incorrectos consecutivos
    inject_error = 1'b1;

    repeat(3)
        @(negedge clock);

    // Debe haber hecho UNLOCK
    if (o_lock !== 1'b0)
    begin
        $display("TEST 4 FAIL: no hizo UNLOCK despues de 3 datos incorrectos");
        $finish;
    end

    inject_error = 1'b0;

    $display("TEST 4 PASS: 5 correctos -> LOCK, 3 incorrectos -> UNLOCK");

    $finish;
end

`endif

`ifdef TEST_5

initial
begin
    $display("========== TEST 5 ==========");

    // Inicializacion
    reset_generator = 1'b1;
    reset_checker   = 1'b1;
    i_valid         = 1'b0;
    i_seed          = 16'hFFFF;
    i_soft_reset    = 1'b0;
    inject_error    = 1'b0;

    #200;

    // Arranca generator + checker
    reset_generator = 1'b0;
    reset_checker   = 1'b0;
    i_valid         = 1'b1;

    // Primero dejamos que el checker haga LOCK
    repeat(6)
        @(posedge clock);

    @(negedge clock);

    if (o_lock !== 1'b1)
    begin
        $display("TEST 5 FAIL: no hizo LOCK inicialmente");
        $finish;
    end

    $display("Checker inicialmente LOCKED");


    // Realizamos varios resets aleatorios SOLO al checker
    for (integer j = 0; j < 10; j = j + 1)
    begin

        // Esperar una cantidad aleatoria de ciclos
        random_wait = $urandom_range(20, 1);

        repeat(random_wait)
            @(negedge clock);

        $display("[%0t ns] Reset aleatorio del checker", $time);

        // Reset SOLO del checker
        reset_checker = 1'b1;

        // Lo mantenemos un ciclo en reset
        @(negedge clock);

        reset_checker = 1'b0;

        // Al salir del reset:
        // 1 dato para sincronizar + 5 correctos para LOCK
        repeat(6)
            @(posedge clock);

        @(negedge clock);

        // Debe haberse resincronizado
        if (o_lock !== 1'b1)
        begin
            $display(
                "TEST 5 FAIL: no recupero LOCK despues del reset %0d",
                j + 1
            );
            $finish;
        end

        $display(
            "Reset %0d: checker recupero LOCK correctamente",
            j + 1
        );

    end

    $display("TEST 5 PASS: recupero LOCK despues de todos los resets aleatorios");

    $finish;
end

`endif
endmodule

//restaura el comportamiento normal para que ese cambio no afecte otros archivos compilados después
`default_nettype wire 