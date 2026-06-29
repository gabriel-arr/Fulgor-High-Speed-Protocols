`default_nettype none
`timescale 1ns/1ns

module top_leds_tb();

localparam N_SWITCH = 4 ;
localparam N_LED    = 4 ;

wire [N_LED - 1 : 0] o_led  ;
wire [N_LED - 1 : 0] o_led_b;
wire [N_LED - 1 : 0] o_led_g;

reg  [N_SWITCH - 1 : 0] i_sw;
reg                     i_reset;
reg                     clock;

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
  clock   <= 'd0;
end
always #5 clock = ~clock;


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


`define TEST1
`define TEST2
`define TEST3
`define TEST4
`define TEST5

`ifdef TEST1 //enable

// `include "./test1.sv"

  localparam NB_COUNTER = 32;

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

`ifdef TEST2 //reset
  reg [N_LED-1:0] estado_leds = 'b0;
  
  initial 
  begin
    force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

    for(integer i=0; i<100; i=i+1)
    begin 
      i_sw[0] = 1'b1;
      #($urandom_range(1,5)*1us);
      reset();
      //esto porque debemos esperar que se actualice los valores de los leds con el siguiente ciclo de clock
      @(posedge clock);
      estado_leds = o_led;
      if(estado_leds != 4'b1000)
      begin 
        $display("ERROR: El valor de reset es incorrecto");
        $display("test failed");
        //el parametro 2 indica retorno con error
        $finish(2);
      end 
    end
    $display ("TEST PASSED");
    $finish();
  end 

`endif 

function verificar_color_verde;
begin
  verificar_color_verde = (i_sw[3] == 1'b0 && o_led_g == u_top_leds.led_enable);
end
endfunction

function verificar_color_azul;
begin
    verificar_color_azul = (i_sw[3]==1'b1 && o_led_b == u_top_leds.led_enable);
end
endfunction

`ifdef TEST3 //color de leds
  initial   
  i_sw[3] = 'b0;
  begin
  force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
  force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
  force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
  force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

  for(integer i=0; i<100; i=i+1)
  begin
    i_sw[3] = $urandom_range(0,1);
    i_sw[0]=$urandom_range(0,1);
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


`ifdef TEST4 //clock
  reg [N_LED-1:0] estado_leds = 'b0;
initial 
begin
  force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
  force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
  force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
  force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

  for(integer i=0; i<100; i=i+1)
  begin
    #($urandom_range(1,5)*1us); //verificar limite
    force clock = clock;
    estado_leds = o_led;
    #($urandom_range(1,5)*1us);
    if(estado_leds != o_led)
    begin
      release clock;
      $display("ERROR : Cambio d  e estado asincronico");
      $finish(2);
    end
  end
  release clock;
  $display("TEST PASSED");
  $finish();
end
`endif

`ifdef TEST5 //limites
initial 
reg count = 0;
reg [N_LED-1:0] esperado = 'b0;
reg [N_LED-1:0] estado_actual = 'b0;
begin
  force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
  force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
  force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
  force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

  for(integer i=0; i<100; i=i+1)
  begin
    count = 0;
    #($urandom_range(1,5)*1us)
    i_sw[2:1] = $urandom_range(0,3);
    //reseteo para conocer el valor inicial
    reset();
    //activo el circuito
    i_sw[0] = 1'b1;
    //alamceno el valor inicial (1000 despues del reset)
    estado_actual = o_led;
    //debido que al resetear el circuito counter=0 entonces o_shift=1 
    //se produce el shift instantaneamente luego del reset, por lo que ignoro el primer shift
    while(o_led == estado_actual)
    begin
      @(posedge clock);
    end

    //alamceno valor luego del primer shift
    estado_actual = o_led;
    //mientras no cambie de estado, cuento flancos de clock
    while (o_led == estado_actual) 
    begin
      @(posedge clock);
      count=count+1;
    end
    //verifico que haga el shift de manera correcta
    esperado = {estado_actual[0], estado_actual[3:1]};
    if(o_led != esperado)
    begin
        $display("ERROR: Valor de shift incorrecto");
        $finish(2);
    end
    //cambio el estado del led, verifico si efectivamente el cambio fue en el valor del limite
    case(i_sw[2:1])
      2'b00: if((count != u_top_leds.u_counter.limit_0+1))
              begin
                $display("ERROR: Cambia en otro limite");
                $finish(2);
              end
      2'b01: if((count != u_top_leds.u_counter.limit_1+1))
              begin
                $display("ERROR: Cambia en otro limite");
                $finish(2);
              end
      2'b10: if((count != u_top_leds.u_counter.limit_2+1))
              begin
                $display("ERROR: Cambia en otro limite");
                $finish(2);
              end
      2'b11: if((count != u_top_leds.u_counter.limit_3+1))
              begin
                $display("ERROR: Cambia en otro limite");
                $finish(2);
              end
      default $display("Combinacion invalida");
    endcase 
  end
  $display("TEST PASSED");
  $finish();
end
`endif 
endmodule

