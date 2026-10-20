module lfsr_checker #(
    parameter N_BITS = 16
)(
    input               clock,
    input               i_reset,
    input               i_valid,
    input [N_BITS-1:0]  i_data,
    output reg          o_lock
);
//DEFINICION DE PARAMETROS
localparam UNLOCKED = 1'b0;
localparam LOCKED = 1'b1;

//DEFINICION DE VARIABLES
reg [N_BITS-1:0] checker_lfsr;
reg              synced; 
reg              state;   
reg[3-1:0]       count;

function [N_BITS-1:0] lfsr_next;
    input [N_BITS-1:0] current;
    reg feedback;
    begin
        feedback = current[N_BITS-1];
        lfsr_next[0] = feedback;
        lfsr_next[1] = current[0];
        lfsr_next[2] = current[1] ^ feedback;
        lfsr_next[3] = current[2] ^ feedback;
        lfsr_next[4] = current[3];
        lfsr_next[5] = current[4] ^ feedback;
        lfsr_next[6] = current[5];
        lfsr_next[7] = current[6];
        lfsr_next[8] = current[7];
        lfsr_next[9] = current[8];
        lfsr_next[10] = current[9];
        lfsr_next[11] = current[10];
        lfsr_next[12] = current[11];
        lfsr_next[13] = current[12];
        lfsr_next[14] = current[13];
        lfsr_next[15] = current[14];
    end
endfunction

always @(posedge clock or posedge i_reset)
begin
  if (i_reset) 
  begin
    checker_lfsr <= 'b0;
    synced <= 1'b0;
  end
  else if (!synced && i_valid)
  begin
    checker_lfsr <= lfsr_next(i_data);
    synced <= 1'b1;
  end 
  else if(synced && i_valid)
  begin
    checker_lfsr <= lfsr_next(checker_lfsr);
  end
end 

always @(posedge clock or posedge i_reset)
begin
    if(i_reset)
    begin
        state <= UNLOCKED;
        count <= 3'b0;
        o_lock <= 1'b0;
    end
    else 
    begin
        case (state)
        UNLOCKED:
        begin
            //completar codigo, sincronizar con i_data y contar 5 seguidas para bloquear
            if(checker_lfsr == i_data && synced && i_valid)
            begin
                if(count == 3'b100)
                begin
                    state <= LOCKED;
                    count <= 3'b0;
                    o_lock <= 1'b1;
                end
                else
                    count <= count + 1;
            end
            if(checker_lfsr != i_data && synced && i_valid)
            begin
                count <= 3'b0;
            end
        end
        LOCKED:
        begin
            //completar codigo, contar 3 seguidas para desbloquear
            if(checker_lfsr != i_data && synced && i_valid)
            begin
                if(count == 3'b010)
                begin
                    o_lock <= 1'b0;
                    state <= UNLOCKED;
                    count <= 'b0;
                end
                else
                begin
                    count <= count + 1'b1;
                end
            end
            if(checker_lfsr == i_data && synced && i_valid)
            begin
                count <= 'b0;
            end
        end
    endcase 
    end
end

endmodule
 