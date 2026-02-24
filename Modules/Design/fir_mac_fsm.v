// Máquina de Estados - Finite State Machine
// IDLE, CAPTURE, SHIFT_REG, LOOP_MAC, DELIVER

module fir_mac_fsm #(
    parameter NUM_TAPS = 8,
    parameter COEFF_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 19 // DATA_WIDTH + COEFF_WIDTH + log2(NUM_TAPS) Guard Bits
)(
    input wire clock,
    input wire reset,
    input wire load_en,
    input wire signed [DATA_WIDTH-1:0] x_in,
    output reg data_valid,
    output reg signed [DATA_WIDTH-1:0] y_out
);

    // Definição dos Estados do Filtro FIR
    localparam IDLE = 3'd0;
    localparam CAPTURE = 3'd1;
    localparam SHIFT = 3'd2;
    localparam LOOP_MAC = 3'd3;
    localparam DELIVER = 3'd4;

    reg [2:0] state, next_state;

    reg signed [COEFF_WIDTH-1:0] rom [0:NUM_TAPS-1];

    integer i;
    initial begin
        for (i = 0; i < NUM_TAPS; i = i + 1)
            rom[i] = 0;
    end

    reg signed [DATA_WIDTH-1:0] x_reg [0:NUM_TAPS-1];
    reg signed [ACC_WIDTH-1:0] acc_reg;

    reg mac_done;
    reg [$clog2(NUM_TAPS)-1:0] count;

    // Reset Síncrono em Nível Lógico 1
    always @(posedge clock) begin

        if (reset) 
            state <= IDLE;
        else 
            state <= next_state;

    end

    // Lógica Combinacional de Próximo Estado
    always @(*) begin

        next_state = state;

        case (state)

            IDLE: begin
                if (load_en)
                    next_state = CAPTURE;
                else 
                    next_state = IDLE;
            end

            CAPTURE:
                next_state = SHIFT;

            SHIFT:
                next_state = LOOP_MAC;

            LOOP_MAC: begin
                if (mac_done)
                    next_state = DELIVER;
                else
                    next_state = LOOP_MAC;
            end

            DELIVER:
                next_state = IDLE;

            default:
                next_state = IDLE;

        endcase
        
    end

    // Lógica de Controle da Unidade de Dados
    always @(posedge clock) begin

        if (reset) begin
            
            mac_done <= 0;
            count <= 0;
            acc_reg <= 0;
            data_valid <= 0;
            y_out <= 0;

        end else begin

            case (state)
            
                IDLE: begin
                    mac_done <= 0;
                    count <= 0;
                    acc_reg <= 0;
                    data_valid <= 0;
                    y_out <= 0;
                end

                CAPTURE: begin
                    // TODO: Carrega a Amostra no Registrador Auxiliar
                end

                SHIFT: begin
                    // TODO: Atualização da Linha de Atraso na Memória
                end

                LOOP_MAC: begin
                    // TODO: Ciclo Iterativo de Leitura, Multiplicação e Acúmulo
                end

                DELIVER: begin
                    // TODO: Amostra Filtrada e Ativação da Saída y[n]
                end

                default: begin
                    mac_done <= 0;
                    count <= 0;
                    acc_reg <= 0;
                    data_valid <= 0;
                end

            endcase

        end

    end

endmodule