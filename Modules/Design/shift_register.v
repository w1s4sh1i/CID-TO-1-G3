// =============================================================================
// Módulo: shift_register
// Descrição: Linha de atraso para o filtro FIR com arquitetura MAC única.
//            Armazena as K amostras mais recentes: x[n], x[n-1], ..., x[n-K+1].
//            A saída é um barramento plano com todos os taps disponíveis
//            simultaneamente para o MUX de seleção.
//
// Parâmetros:
//   DATA_WIDTH : Largura em bits de cada amostra (ponto fixo, complemento de dois)
//   NUM_TAPS   : Número de taps do filtro (mínimo 8)
//
// Portas:
//   clk        : Clock do sistema
//   rst        : Reset síncrono, ativo em nível alto
//   shift_en   : Habilita o deslocamento (ativado no estado SHIFT da FSM)
//   data_in    : Nova amostra de entrada x[n]
//   taps_out   : Barramento com todos os taps [x[n], x[n-1], ..., x[n-K+1]]
//                Organizado como: taps_out[(k+1)*DATA_WIDTH-1 : k*DATA_WIDTH] = x[n-k]
// =============================================================================

// O deslocamento ocorre em paralelo, assim as palavras são transmitidas inteiras em um único ciclo de clock 
//            bit7   bit6   bit5   bit4   bit3   bit2   bit1   bit0
//            ────   ────   ────   ────   ────   ────   ────   ────
// reg_mem[0] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n]
// reg_mem[1] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-1]
// reg_mem[2] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-2]
// reg_mem[3] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-3]
// reg_mem[4] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-4]
// reg_mem[5] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-5]
// reg_mem[6] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-6]
// reg_mem[7] [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]   [FF]  → x[n-7]
// Há um deslocamento da "linha" inteira a cada ciclo de clock

module shift_register #(
    parameter DATA_WIDTH = 8,
    parameter NUM_TAPS   = 8
)(
    input  wire                            clk,
    input  wire                            rst,
    input  wire                            shift_en,
    input  wire signed [DATA_WIDTH-1:0]    data_in,
    output wire signed [NUM_TAPS*DATA_WIDTH-1:0] taps_out
);

    // Registradores internos: reg_mem[0] = x[n] (mais recente)
    //                         reg_mem[K-1] = x[n-K+1] (mais antiga)
    reg signed [DATA_WIDTH-1:0] reg_mem [0:NUM_TAPS-1];

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < NUM_TAPS; i = i + 1)
                reg_mem[i] <= {DATA_WIDTH{1'b0}};
        end else if (shift_en) begin
            // Desloca: a cada nova amostra, empurra as antigas para posições maiores
            for (i = NUM_TAPS-1; i > 0; i = i - 1)
                reg_mem[i] <= reg_mem[i-1];
            reg_mem[0] <= data_in;  // x[n] entra na posição 0
        end
    end

    // Mapeia o array interno para o barramento de saída plano
    // taps_out[(k+1)*DATA_WIDTH-1 : k*DATA_WIDTH] corresponde a x[n-k]
    genvar k;
    generate
        for (k = 0; k < NUM_TAPS; k = k + 1) begin : gen_taps_out
            assign taps_out[(k+1)*DATA_WIDTH-1 : k*DATA_WIDTH] = reg_mem[k];
        end
    endgenerate

endmodule
