/*******************************************************
Arquitetura geral

Parâmetros do Projeto:
parameter K  = 8;    // número de taps (mínimo 8)
parameter DW = 8;    // largura da entrada x
parameter CW = 8;    // largura coeficientes h

Unidade de Controle (FSM)
-> IDLE
-> CAPTURE
-> SHIFT
-> PROCESS (loop MAC por K ciclos)
-> DONE (data_valid = 1 por 1 ciclo)

fir_project/
│
├── fir_top.v
├── fir_control.v
├── fir_datapath.v
│
├── datapath/
│   ├── shift_register.v
│   ├── tap_counter.v
│   ├── mux_taps.v
│   ├── acc_mux.v
│   ├── rom.v
│
├── coeffs/
│   └── fir_coeffs.mem
│
└── tb/
    └── tb_fir.v

O projeto foi estruturado de forma hierárquica.
O módulo top conecta a unidade de controle e a unidade de dados.
A unidade de dados contém o shift register, ROM de coeficientes e a unidade MAC.
Essa divisão garante modularidade e reutilização de hardware conforme exigido.

*******************************************************************************/   

/******************************************************************************
O Módulo Top é o bloco principal do projeto.
-> Conecta todos os outros módulos
-> Organiza a arquitetura completa
-> É a interface externa do sistema

*****************************************************************************

                 +----------------+
                 |    fir_top     |
                 +----------------+
                     |        |
          +----------+        +-----------+
          |                               |
   +-------------+                 +---------------+
   | fir_control |                 | fir_datapath  |
   +-------------+                 +---------------+
                                          |
    ---------------------------------------------------------
    |     |        |        |        |         |            |
 shift  tap_cnt   ROM     MUX     Mult     Accumulator   y_reg

********************************************************************************/

module fir_top #(
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

    // ===============================
    // Sinais de controle
    // ===============================

    wire shift_en;
    wire mac_en;
    wire acc_clear;
    wire tap_en;

    // ===============================
    // Tap index
    // ===============================

    wire [$clog2(K)-1:0] tap_index;

    // ===============================
    // FSM de Controle
    // ===============================

    fir_control #(
        .K(K)
    ) u_fir_control (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .shift_en   (shift_en),
        .tap_en     (tap_en),
        .acc_clear  (acc_clear),
        .mac_en     (mac_en),
        .tap_index  (tap_index),
        .data_valid (data_valid)
    );

    // ===============================
    // Datapath FIR
    // ===============================

    fir_datapath #(
        .K (K),
        .DW(DW),
        .CW(CW)
    ) u_fir_datapath (
        .clk       (clk),
        .rst       (rst),
        .shift_en  (shift_en),
        .mac_en    (mac_en),
        .acc_clear (acc_clear),
        .x_in      (x_in),
        .tap_index (tap_index),
        .y_out     (y_out)
    );

endmodule


/************ Sequência do MAC ***************************************

| Ciclo | Estado  | tap_index | mac_en | Observação       |
| ----- | ------- | --------- | ------ | ---------------- |
| 1     | CAPTURE | 0         | 0      | limpa acumulador |
| 2     | SHIFT   | 0         | 0      | shift amostra    |
| 3     | PROCESS | 0         | 1      | 1º MAC           |
| 4     | PROCESS | 1         | 1      | 2º MAC           |
| ...   | ...     | ...       | ...    | ...              |
| K+2   | PROCESS | K-1       | 1      | Último MAC       |
| K+3   | DONE    | K-1       | 0      | data_valid=1     |


/******** Mapeamento em FPGA ********************************

| Bloco          | Hardware real |
| -------------- | ------------- |
| shift_register | Flip-Flops    |
| mux_taps       | LUT           |
| ROM            | BRAM          |
| Multiplier     | DSP           |
| Adder          | Carry Chain   |
| Accumulator    | Registradores |
| Output Reg     | Flip-Flop     |

/*********************************************************************/


