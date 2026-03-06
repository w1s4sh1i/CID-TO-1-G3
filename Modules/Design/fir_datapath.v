/*******************************************************************************
Datapath é o bloco responsável por:
Fazer todas as operações matemáticas do filtro FIR
Contém:
Shift register (linha de atraso)
ROM coeficientes
MUX seleção tap
Multiplicador
Somador
Acumulador
Registrador de saída

Estrutura do Datapath:

Shift Register
      ↓
MUX Taps
      ↓
ROM
      ↓
     MAC
      ↓
Output Register

Funcionamento:
--> CAPTURE
acc_clear = 1
MAC zera acumulador
--> PROCESS
mac_en = 1
MAC faz: acc = acc + (sample * coeff)
--> Último tap
tap_index == K-1
→ y_out recebe mac_out
/******************************************************************************/

module fir_datapath #(
    parameter K  = 8,
    parameter DW = 8,
    parameter CW = 8
)(
    input  wire clk,
    input  wire rst,

    // ===== Controle vindo da FSM =====
    input  wire shift_en,
    input  wire mac_en,
    input  wire acc_clear,
    input  wire [$clog2(K)-1:0] tap_index,

    // ===== Dados =====
    input  wire signed [DW-1:0] x_in,

    // ===== Saída =====
    output reg  signed [DW+CW+$clog2(K):0] y_out
);

    // ======================================================
    // Larguras internas
    // ======================================================

    localparam PW = DW + CW;
    localparam AW = PW + $clog2(K) + 1;

    // ======================================================
    // SHIFT REGISTER
    // ======================================================

    wire signed [K*DW-1:0] taps_bus;

    shift_register #(
        .DATA_WIDTH(DW),
        .NUM_TAPS  (K)
    ) u_shift_register (
        .clk      (clk),
        .rst      (rst),
        .shift_en (shift_en),
        .data_in  (x_in),
        .taps_out (taps_bus)
    );

    // ======================================================
    // MUX DE TAPS
    // ======================================================

    wire signed [DW-1:0] sample;

    mux_taps #(
        .DATA_WIDTH(DW),
        .NUM_TAPS  (K)
    ) u_mux_taps (
        .taps_in  (taps_bus),
        .tap_index(tap_index),
        .data_out (sample)
    );

    // ======================================================
    // ROM DE COEFICIENTES
    // ======================================================

    wire signed [CW-1:0] coeff_rom;

    rom #(
        .NUM_TAPS   (K),
        .COEFF_WIDTH(CW)
        // .FILE_NAME  ("fir_coeffs.hex")
    ) u_rom (
        .addr (tap_index),
        .coeff(coeff_rom)
    );

    // ======================================================
    // BLOCO MAC
    // ======================================================

    wire signed [AW-1:0] mac_out;

    mac #(
        .DW(DW),
        .CW(CW),
        .AW(AW)
    ) u_mac (
        .clk        (clk),
        .rst        (rst),
        .data_in    (sample),
        .coeff_in   (coeff_rom),
        .ps         (mac_en),     // acumular durante PROCESS
        .l_acc      (acc_clear),  // limpar no CAPTURE
        .load_value ({AW{1'b0}}), // não usamos carga externa
        .acc_out    (mac_out)
    );

    // ======================================================
    // REGISTRADOR DE SAÍDA
    // ======================================================

    always @(posedge clk or posedge rst) begin
        if (rst)
            y_out <= 0;
        else if (mac_en && (tap_index == K-1))
            y_out <= mac_out;
    end

endmodule