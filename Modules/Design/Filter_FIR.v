/*******************************************************
Arquitetura geral
fir_top
 ├── fir_control  (FSM)
 ├── fir_datapath (MAC + shift register + ROM)

Fluxo por amostra:
 -> CAPTURE
 -> SHIFT
 -> PROCESS (loop MAC por K ciclos)
 -> DONE (data_valid = 1 por 1 ciclo)

Parâmetros do Projeto:
parameter K  = 8;    // número de taps (mínimo 8)
parameter DW = 8;    // largura da entrada x
parameter CW = 8;    // largura coeficientes h

Unidade de Controle (FSM)
-> IDLE
-> CAPTURE
-> SHIFT
-> PROCESS

FIR_top
│
├── FIR_control
│     └── FSM states
│
└── FIR_datapath
      ├── shift_register
      ├── coefficient_ROM
      ├── multiplier
      ├── adder
      ├── accumulator
      └── output_register

O projeto foi estruturado de forma hierárquica.
O módulo top conecta a unidade de controle e a unidade de dados.
A unidade de dados contém o shift register, ROM de coeficientes e a unidade MAC.
Essa divisão garante modularidade e reutilização de hardware conforme exigido.

*******************************************************************************/   

/*******************************************************************************
FSM_control é a Unidade de Controle (FSM – Finite State Machine) do filtro FIR.
Controla quando cada operação deve acontecer.
********************************************************************************/

module FIR_control #(
    parameter K = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire start,              // nova amostra disponível
    output reg  shift_en,
    output reg  acc_clear,
    output reg  mac_en,
    output reg  data_valid,
    output reg  [$clog2(K)-1:0] tap_index
);

localparam IDLE    = 3'd0;
localparam CAPTURE = 3'd1;
localparam SHIFT   = 3'd2;
localparam PROCESS = 3'd3;
localparam DONE    = 3'd4;

reg [2:0] state, next_state;

always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE:    if (start) next_state = CAPTURE;
        CAPTURE: next_state = SHIFT;
        SHIFT:   next_state = PROCESS;
        PROCESS: if (tap_index == K-1) next_state = DONE;
        DONE:    next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tap_index <= 0;
        shift_en  <= 0;
        mac_en    <= 0;
        acc_clear <= 0;
        data_valid<= 0;
    end else begin
        shift_en   <= 0;
        mac_en     <= 0;
        acc_clear  <= 0;
        data_valid <= 0;

        case(state)

            CAPTURE: begin
                acc_clear <= 1;
                tap_index <= 0;
            end

            SHIFT: begin
                shift_en <= 1;
            end

            PROCESS: begin
                mac_en <= 1;
                tap_index <= tap_index + 1;
            end

            DONE: begin
                data_valid <= 1;
            end
        endcase
    end
end

endmodule
 
/***************************************************************************
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

module FIR_datapath #(
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

/**********************************************************************
O Módulo Top é o bloco principal do projeto.
-> Conecta todos os outros módulos
-> Organiza a arquitetura completa
-> É a interface externa do sistema

**********************************************************************/

module FIR_top #(
    parameter K  = 8,
    parameter DW = 8,
    parameter CW = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire signed [DW-1:0] x_in,
    output wire signed [DW+CW+$clog2(K):0] y_out,
    output wire data_valid
);

wire shift_en;
wire mac_en;
wire acc_clear;
wire [$clog2(K)-1:0] tap_index;

fir_control #(K) control (
    .clk(clk),
    .rst(rst),
    .start(start),
    .shift_en(shift_en),
    .acc_clear(acc_clear),
    .mac_en(mac_en),
    .data_valid(data_valid),
    .tap_index(tap_index)
);

fir_datapath #(K, DW, CW) datapath (
    .clk(clk),
    .rst(rst),
    .shift_en(shift_en),
    .mac_en(mac_en),
    .acc_clear(acc_clear),
    .x_in(x_in),
    .tap_index(tap_index),
    .y_out(y_out)
);

endmodule

  