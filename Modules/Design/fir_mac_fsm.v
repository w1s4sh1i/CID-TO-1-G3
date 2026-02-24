// Máquina de Estados - Finite State Machine
// IDLE, CAPTURE, SHIFT_REG, LOOP_MAC, DELIVER

module fir_mac_fsm #(
    parameter NUM_TAPS = 8,
    parameter DATA_WIDTH = 8,
    parameter COEFF_WIDTH = 8,
    parameter ACC_WIDTH = 19
)(
    input wire clock,
    input wire reset,
    input wire load_en
);

    // Definição dos Estados do Filtro FIR
    localparam IDLE = 3'd0;
    localparam CAPTURE = 3'd1;
    localparam SHIFT = 3'd2;
    localparam LOOP_MAC = 3'd3;
    localparam DELIVER = 3'd4;

    reg [2:0] state, next_state;

    // Reset Assíncrono em Nível Lógico 1
    always @(posedge clock or posedge reset) begin

        if (reset) 
            state <= IDLE;
        else 
            state <= next_state;

    end

    // Lógica Combinacional de Próximo Estado
    always @(*) begin

        case (state)

            IDLE:
                if (load_en)
                    next_state = CAPTURE;
                else 
                    next_state = IDLE;

            CAPTURE:
                next_state = SHIFT;

            SHIFT:
                next_state = LOOP_MAC;

            LOOP_MAC:
                if (mac_done)
                    next_state = DELIVER;
                else
                    next_state = LOOP_MAC;

            DELIVER:
                next_state = IDLE;

            default:
                next_state = IDLE;

        endcase
        
    end

    // Lógica de Controle da Unidade de Dados
    always @(posedge clock or posedge reset) begin

        case (param)
            
            IDLE:
                // Zera Parâmetros e Aguarda Novas Entradas

            CAPTURE:
                // Carrega a Amostra no Registrador Auxiliar

            SHIFT:
                // Atualização da Linha de Atraso na Memória

            LOOP_MAC:
                // Ciclo Iterativo de Leitura, Multiplicação e Acúmulo

            DELIVER:
                // Amostra Filtrada e Ativação da Saída y[n]
                
            default: 

        endcase

    end

endmodule