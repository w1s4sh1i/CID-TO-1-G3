/*******************************************************************************
fir_control é a Unidade de Controle (FSM – Finite State Machine) do filtro FIR.
Controla quando cada operação deve acontecer.
********************************************************************************/

module fir_control #(
    parameter K = 8
  )(
    input  wire clk,
    input  wire rst,
    input  wire start,

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

  // =====================================================
  // Registrador de estado
  // =====================================================

  always @(posedge clk or posedge rst)
  begin
    if (rst)
      state <= IDLE;
    else
      state <= next_state;
  end

  // =====================================================
  // Próximo estado
  // =====================================================

  always @(*)
  begin
    next_state = state;

    case (state)
      IDLE:
        if (start)
          next_state = CAPTURE;

      CAPTURE:
        next_state = SHIFT;

      SHIFT:
        next_state = PROCESS;

      PROCESS:
        if (tap_index == K-1)
          next_state = DONE;

      DONE:
        next_state = IDLE;
    endcase
  end

  // =====================================================
  // Contador de taps (sequencial)
  // =====================================================

  always @(posedge clk or posedge rst)
  begin
    if (rst)
      tap_index <= 0;
    else
    begin
      case (state)
        CAPTURE: tap_index <= 0;
        PROCESS:
          if (tap_index < K-1)
            tap_index <= tap_index + 1;
        default: ;
      endcase
    end
  end

  // =====================================================
  // Saídas combinacionais (Moore FSM)
  // Cada saída é válida no mesmo ciclo do estado,
  // eliminando o escorregamento de 1 ciclo que fazia
  // mac_en chegar quando tap_index já era 1 (tap 0 pulado).
  // =====================================================

  always @(state)
  begin
    shift_en   = 1'b0;
    mac_en     = 1'b0;
    acc_clear  = 1'b0;
    data_valid = 1'b0;

    case (state)
      CAPTURE: acc_clear  = 1'b1;
      SHIFT:   shift_en   = 1'b1;
      PROCESS: mac_en     = 1'b1;
      DONE:    data_valid = 1'b1;
      default: ;
    endcase
  end

endmodule
