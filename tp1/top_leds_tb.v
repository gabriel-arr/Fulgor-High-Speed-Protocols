`default_nettype none
`timescale 1ns/1ns

module top_leds_tb();

localparam N_SWITCH = 4 ;
localparam N_LED    = 4 ;
localparam NB_COUNTER = 32;

wire [N_LED - 1 : 0] o_led  ;
wire [N_LED - 1 : 0] o_led_b;
wire [N_LED - 1 : 0] o_led_g;

reg  [N_SWITCH - 1 : 0] i_sw;
reg                     i_reset;
reg                     clock;
reg                     clock_stopped;

top_leds
u_top_leds
(
//----> Output
  .o_led      (o_led),
  .o_led_b    (o_led_b),
  .o_led_g    (o_led_g),
//----> Inputs
  .i_sw       (i_sw   ),
  .i_reset    (i_reset),
  .clock      (clock  )
);


//----> Generamos clock
initial
begin
  clock        <= 'd0;
  clock_stopped <= 1'b0;
end
always #5 if (!clock_stopped) clock = ~clock;


//----> Task para el reset
task reset ();
time reset_time;
begin
  //----> Reset en 0
  i_reset <= 'd0;

  //----> Randomizo duracion del reset
  reset_time = $urandom_range(1,100);
  //----> Espero el tiempo random
  #reset_time;

  //----> Levanto reset de manera sincronica
  //---> Esperamos un flanco de clock
  @(posedge clock);

  //----> Levanto reset
  i_reset <= 'd1; 
end
endtask


// Descomentar solo uno de estos defines para ejecutar un test a la vez.
`define TEST1
//`define TEST2
//`define TEST3
//`define TEST4
//`define TEST5
//`define TEST6

`ifdef TEST1 //enable

// `include "./test1.sv"

  

  reg [N_LED      - 1 : 0] prev_o_led    ;
  reg [NB_COUNTER - 1 : 0] clock_counter ;

  initial
  begin

    force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

    //----> Corremos el test por 100 iteraciones
    for(integer i=0; i<100; i=i+1)
    begin

      //----> Inicializamos las variables
      i_sw[0]       = 'd0;
      i_sw[3:1]     = $urandom_range(0,7);
      prev_o_led    = 'd0;
      clock_counter = 'd0;

      //----> Reset
      reset();

      //----> Habilitamos el contador
      i_sw[0] = 'd1;

      //----> Esperamos un momento random
      #($urandom_range(1,5) * 1us);

      //----> Deshabilitamos el contador y guardamos el valor del led en ese instante.
      i_sw[0]     = 'd0   ;
      prev_o_led  = o_led ;

      //----> Esperamos un momento random.
      clock_counter = $urandom_range(50,500);

      //----> Checkeamos funcionamiento.
      for(integer j=0; j<clock_counter; j=j+1)
      begin
        @(posedge clock);
        if(prev_o_led != o_led)
        begin
          $display("ERROR: El valor del led cambio.");
          $display("TEST FAILED");
          $finish(2);
        end 
      end
    end

    $display("TEST PASSED");
    $finish();
  end
`endif

`ifdef TEST2 // reset
  reg [N_LED-1:0] estado_objetivo;
  reg [N_LED-1:0] estado_pre_reset;
  integer i;
  integer timeout;

  localparam [N_LED-1:0] VALOR_RESET = 4'b1000;

  initial
  begin
    force u_top_leds.u_counter.limit_0 = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1 = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2 = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3 = 32'h0000_0080;

    i_sw = 4'b0000;
    i_reset = 1'b1;
    estado_objetivo = 4'b0000;
    estado_pre_reset = 4'b0000;
    timeout = 0;

    for(i=0; i<100; i=i+1)
    begin
      i_sw[3:1] = $urandom_range(0,7);
      i_sw[0]   = 1'b0;

      reset();

      #1;

      if(o_led != VALOR_RESET)
      begin
        $display("ERROR: Reset con enable=0 incorrecto. Leido: %b, esperado: %b", o_led, VALOR_RESET);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end

      if(u_top_leds.u_counter.counter != 32'd0)
      begin
        $display("ERROR: Counter no quedo en 0 con enable=0. Leido: %0d", u_top_leds.u_counter.counter);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end

      // Activo enable
      @(negedge clock);
      i_sw[0] = 1'b1;

      // Elijo un estado donde el salto a 8 NO sea natural
      if($urandom_range(0,1))
        estado_objetivo = 4'b0100; // 4
      else
        estado_objetivo = 4'b0010; // 2

      // Espero a que el circuito salga del estado inicial
      timeout = 0;

      // Espero hasta que el LED llegue a 4 o 2
      while(o_led != estado_objetivo && timeout < 500)
      begin
        @(posedge clock);
        #1;
        timeout = timeout + 1;
      end

      if(o_led != estado_objetivo)
      begin
        $display("ERROR: El circuito no llego al estado objetivo antes del reset.");
        $display("Estado objetivo: %b, estado actual: %b", estado_objetivo, o_led);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end

      estado_pre_reset = o_led;

      // Aplico reset en mitad del ciclo, no justo en el posedge
      #($urandom_range(2,7));

      reset();

      #1;

      if(o_led != VALOR_RESET)
      begin
        $display("ERROR: Reset con enable=1 incorrecto.");
        $display("Estado antes del reset: %b", estado_pre_reset);
        $display("Leido: %b, esperado: %b", o_led, VALOR_RESET);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end

      if(u_top_leds.u_counter.counter != 32'd0)
      begin
        $display("ERROR: Counter no quedo en 0 con enable=1. Leido: %0d", u_top_leds.u_counter.counter);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end
    end

    $display("TEST PASSED");
    $finish();
  end

`endif

function verificar_color_verde;
begin
  verificar_color_verde = (i_sw[3] == 1'b0 && o_led_g == u_top_leds.led_enable && o_led_b == 4'b0000);
end
endfunction

function verificar_color_azul;
begin
    verificar_color_azul = (i_sw[3]==1'b1 && o_led_b == u_top_leds.led_enable && o_led_g == 4'b0000);
end
endfunction

`ifdef TEST3 //color de leds
  initial
  begin
    i_reset = 1'b1;
    i_sw = 4'b0000;
    force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3   = 32'h0000_0080;
    
    reset();
    
    for(integer i=0; i<100; i=i+1)
    begin
      i_sw[3:1] = $urandom_range(0,7);
      i_sw[0] = 1'b1;
      
      @(posedge clock);
      if(i_sw[3]==1'b1)
      begin
        if(!verificar_color_azul())
        begin
          $display("ERROR: Color incorrecto");
          $finish(2);
        end
      end
      else
      begin
        if(!verificar_color_verde())
        begin
          $display("ERROR: Color incorrecto");
          $finish(2);
        end
      end
    end
    $display("TEST PASSED");
    $finish();
  end


`endif


`ifdef TEST4 // clock detenido

  reg [N_LED-1:0] estado_leds;
  reg [NB_COUNTER-1:0] estado_counter;
  integer i;

  initial
  begin
    force u_top_leds.u_counter.limit_0 = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1 = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2 = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3 = 32'h0000_0080;

    i_sw = 4'b0001;
    i_reset = 1'b1;
    clock_stopped = 1'b0;
    estado_leds = {N_LED{1'b0}};
    estado_counter = {NB_COUNTER{1'b0}};

    reset();

    for(i=0; i<100; i=i+1)
    begin
      // dejo avanzar el circuito un tiempo random
      #($urandom_range(100,500));

      // muestreo luego de un flanco, evitando race
      @(posedge clock);
      #1;

      estado_leds    = o_led;
      estado_counter = u_top_leds.u_counter.counter;

      // detengo clock
      clock_stopped = 1'b1;

      // espero con clock detenido
      #($urandom_range(1,5)*1us);

      // verifico que no haya cambios sin clock
      if(estado_leds != o_led)
      begin
        clock_stopped = 1'b0;
        $display("ERROR: o_led cambio con clock detenido");
        $display("Esperado: %b, leido: %b", estado_leds, o_led);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end

      if(estado_counter != u_top_leds.u_counter.counter)
      begin
        clock_stopped = 1'b0;
        $display("ERROR: counter cambio con clock detenido");
        $display("Esperado: %0d, leido: %0d", estado_counter, u_top_leds.u_counter.counter);
        $display("TEST FAILED en iteracion %0d", i);
        $finish(2);
      end

      // reactivo clock
      clock_stopped = 1'b0;

      @(posedge clock);
      #1;
    end

    $display("TEST PASSED");
    $finish();
  end

`endif

function [0:0] limite_incorrecto;
  input reg [31:0] count;
  begin
    case(i_sw[2:1])
      2'b00: limite_incorrecto = (count != u_top_leds.u_counter.limit_0+1);
      2'b01: limite_incorrecto = (count != u_top_leds.u_counter.limit_1+1);
      2'b10: limite_incorrecto = (count != u_top_leds.u_counter.limit_2+1);
      2'b11: limite_incorrecto = (count != u_top_leds.u_counter.limit_3+1);
      default: $display("Combinacion invalida");
    endcase 
  end
endfunction

`ifdef TEST5 //limites
reg [31:0] count;
reg [N_LED-1:0] esperado;
reg [N_LED-1:0] estado_actual;
reg [31:0] timeout;
initial
begin
  force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
  force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
  force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
  force u_top_leds.u_counter.limit_3   = 32'h0000_0080;
  i_sw = 4'b0000;
  i_reset = 1'b1;
  count = 32'd0;
  esperado = 4'b0000;
  estado_actual = 4'b0000;
  timeout = 32'd0;
  reset();

  for(integer i=0; i<100; i=i+1)
  begin
    count = 'b0;
    timeout = 'b0;
    #($urandom_range(1,5)*1us);
    i_sw[2:1] = $urandom_range(0,3);
    //reseteo para conocer el valor inicial
    reset();
    //activo el circuito
    i_sw[0] = 1'b1;
    //alamceno el valor inicial (1000 despues del reset)
    estado_actual = o_led;
    //debido que al resetear el circuito counter=0 entonces o_shift=1 
    //se produce el shift instantaneamente luego del reset, por lo que ignoro el primer shift
    timeout = 'b0;

    while(o_led == estado_actual && timeout < 500)
    begin
      @(posedge clock);
      #1;
      timeout = timeout + 1;
    end

    if(timeout >= 500)
    begin
      $display("ERROR: Timeout esperando el primer shift");
      $finish(2);
    end

    //alamceno valor luego del primer shift
    estado_actual = o_led;
    //mientras no cambie de estado, cuento flancos de clock
    timeout = 'b0;
    while (o_led == estado_actual && timeout < 500) 
    begin
      @(posedge clock);
      #1; //espero un tiempo para que se actualicen los registros
      count=count+1;
      timeout = timeout + 1;
    end
    //verifico que haga el shift de manera correcta
    esperado = {estado_actual[0], estado_actual[3:1]};
    if(o_led != esperado)
    begin
      $display("ERROR: Shifteo incorrecto");
      $finish(2);
    end
    if(timeout >= 500)
    begin
        $display("ERROR: Timeout esperado cambio por limite");
        $finish(2);
    end
    //cambio el estado del led, verifico si efectivamente el cambio fue en el valor del limite
    if(limite_incorrecto(count))
    begin
      $display("ERROR: Cambio de estado en otro limite");
      $finish(2);
    end
  end
  $display("TEST PASSED");
  $finish();
end
`endif 

`ifdef TEST6
reg [N_LED-1:0] valor_actual;
reg [N_LED-1:0] esperado;
reg [NB_COUNTER-1:0] count;
reg [31:0] timeout;
initial 
begin
  force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
  force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
  force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
  force u_top_leds.u_counter.limit_3   = 32'h0000_0080;
  i_sw = 4'b0000;
  i_reset = 1'b1;
  valor_actual = 4'b0000;
  esperado = 4'b0000;
  count = 32'd0;
  timeout = 32'd0;

  for(integer i=0; i<100; i=i+1)
  begin
    //randomizar enable, limite y color
    i_sw[3:0] = $urandom_range(0,15);

    reset();
    #1;
    valor_actual = o_led;
    //comprobamos que no cambie el valor con el enable desactivado
    if(i_sw[0] == 0)
    begin
      //esperamos un tiempo random
      #($urandom_range(1,5)*1us);
      //no espero un cloc porque en el tiempo minimo 1us ya pasaron muchos clocks
      if(o_led != valor_actual)
      begin
        $display("ERROR: CAMBIO DE ESTADO EN LOS LEDS");
        $finish(2);
      end
      case (i_sw[3])
        1'b1:
        begin
          if(!verificar_color_azul())
          begin
            $display("ERROR: COLOR INCORRECTO, ESPERADO: AZUL");
            $finish(2);
          end
        end
         
        1'b0:
        begin
          if(!verificar_color_verde())
          begin
            $display("ERROR: COLOR INCORRECTO, ESPERADO: VERDE");
            $finish(2);
          end
        end
        default: $display("ERROR: Estado no valido para seleccionar color");
      endcase
    end
    //cuando el enable esta activado
    else
    begin
      timeout = 0;
      //luego del reset count=0 entonces cambia inmediatamente, obvio ese primer shift
      while(valor_actual == o_led && timeout < 500)
      begin
        @(posedge clock);
        #1; //se agrega para evitar race conditions
        timeout = timeout + 1;
      end
      if(timeout >= 500)
      begin
        $display("ERROR: Timeout esperando el primer shift");
        $finish(2);
      end
      //pasado el primer shift guardamos el estado real para verificar el shift con el limite
      valor_actual = o_led;
      //aseguro que el contador empiece en 0
      count = 'b0;
      timeout = 'b0;
      while(valor_actual == o_led && timeout < 500)
      begin
        @(posedge clock);
        //espero 1us para que se actualicen los registros y el contador y evitar race conditions
        #1;
        count = count + 1;
        timeout = timeout + 1;
      end
      if(timeout >= 500)
      begin
        $display("ERROR: Timeout esperando el cambio de estado por limite");
        $finish(2);
      end
      //cuando sale del while es porque shifteo es porque shifteo, compruebo que shiftee correctamente
      esperado = {valor_actual[0], valor_actual[3:1]};
      if(o_led != esperado)
      begin
        $display("ERROR: Shiteo incorrecto");
        $finish(2);
      end
      //compruebo el valor del contador coincida con el limite establecido
      if(limite_incorrecto(count))
      begin
        $display("ERROR: SHIFTEO EN VALOR DE LIMITE INCORRECTO");
        $finish(2);
      end
    end
    if(i_sw[3] == 1'b1)
    begin
      if(!verificar_color_azul())
      begin
        $display("ERROR: COLOR INCORRECTO CON ENABLE ACTIVADO");
        $finish(2);
      end
    end
    else
    begin
      if(!verificar_color_verde())
      begin
        $display("ERROR: COLOR INCORRECTO EN TEST DE INTEGRACION");
        $finish(2);
      end
    end
  end
  $display("TEST: PASSED");
  $finish();
end  

`endif

endmodule

