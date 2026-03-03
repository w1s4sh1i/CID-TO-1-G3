/******************************************************************************
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
******************************************************************************/

module fir_datapath #(
    parameter K  = 8,
    parameter DW = 8,
    parameter CW = 8
)(
    input  wire clk,
    input  wire rst,

    input  wire shift_en,
    input  wire mac_en,
    input  wire acc_clear,

    input  wire signed [DW-1:0] x_in,
    input  wire [$clog2(K)-1:0] tap_index,

    output reg  signed [DW+CW+$clog2(K):0] y_out
);

    localparam PW = DW + CW;
    localparam AW = PW + $clog2(K) + 1;

    // -------------------------
    // Shift Register
    // -------------------------

    reg signed [DW-1:0] shift_reg [0:K-1];

    integer i;

    always @(posedge clk) begin
        if (shift_en) begin
            shift_reg[0] <= x_in;
            for (i = 1; i < K; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end

    // -------------------------
    // ROM Coeficientes
    // -------------------------

    reg signed [CW-1:0] coeff_rom [0:K-1];

    initial begin
        $readmemh("coeffs.mem", coeff_rom);
    end

    // -------------------------
    // MAC
    // -------------------------

    wire signed [DW-1:0] sample = shift_reg[tap_index];
    wire signed [CW-1:0] coeff  = coeff_rom[tap_index];

    wire signed [PW-1:0] product;
    assign product = sample * coeff;

    reg signed [AW-1:0] accumulator;

    always @(posedge clk or posedge rst) begin
        if (rst)
            accumulator <= 0;
        else if (acc_clear)
            accumulator <= 0;
        else if (mac_en)
            accumulator <= accumulator + product;
    end

    // -------------------------
    // Latch de saída
    // -------------------------

    always @(posedge clk) begin
        if (mac_en && tap_index == K-1)
            y_out <= accumulator + product;
    end

endmodule