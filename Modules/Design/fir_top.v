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

fir_top
│
├── fir_control
│     └── FSM states
│
└── fir_datapath
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

/**********************************************************************
O Módulo Top é o bloco principal do projeto.
-> Conecta todos os outros módulos
-> Organiza a arquitetura completa
-> É a interface externa do sistema

**********************************************************************/

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
        // .tap_en     (tap_en), -> Sem tap_en no fir_control
        .acc_clear  (acc_clear),
        .mac_en     (mac_en),
        .data_valid (data_valid),
        .tap_index  (tap_index)
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
        // .tap_index (tap_index), -> Sem tap_index no fir_datapath
        .start     (start),
		.tap_en    (tap_en),
        .x_in      (x_in),
        .y_out     (y_out)
    );

endmodule


/**********************************************************************
Sequência do MAC 

Ciclo	     Ação
-----------------------------------------------
1	        shift_en = 1 (entra x[n])
2	        acc_clear = 1, tap_index = 0
3 → K+2	    mac_en = 1, tap_en = 1
Último      data_valid = 1

/*********************************************************************/
