// =============================================================================
// Módulo: mux_taps
// Descrição: MUX parametrizado que seleciona uma amostra do shift register
//            para ser enviada ao multiplicador da unidade MAC.
//            Controlado pelo tap_index gerado pela FSM durante o Loop MAC.
//
// Parâmetros:
//   DATA_WIDTH : Largura em bits de cada amostra (deve ser igual ao shift_register)
//   NUM_TAPS   : Número de entradas do MUX (deve ser igual ao NUM_TAPS do shift_register)
//
// Portas:
//   taps_in    : Barramento plano com todos os taps vindo do shift_register
//   tap_index  : Índice de seleção gerado pela FSM (0 a NUM_TAPS-1)
//   data_out   : Amostra selecionada x[n - tap_index]
// =============================================================================

module mux_taps #(
    parameter DATA_WIDTH = 8,
    parameter NUM_TAPS   = 8
)(
    input  wire [NUM_TAPS*DATA_WIDTH-1:0]       taps_in,
    input  wire [$clog2(NUM_TAPS)-1:0]          tap_index,
    output reg  signed [DATA_WIDTH-1:0]         data_out
);

    // Seleciona o tap correspondente ao índice atual da FSM
    always @(*) begin
        data_out = taps_in[(tap_index+1)*DATA_WIDTH-1 -: DATA_WIDTH];
    end

endmodule
