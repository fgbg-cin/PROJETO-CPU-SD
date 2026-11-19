module module_alu (
    input  wire [2:0]  opcode,
    input  wire [15:0] operando_a,
    input  wire [15:0] operando_b,
    output reg  [15:0] resultado,
    output reg         overflow
);

    localparam OP_LOAD    = 3'b000;
    localparam OP_ADD     = 3'b001;
    localparam OP_ADDI    = 3'b010;
    localparam OP_SUB     = 3'b011;
    localparam OP_SUBI    = 3'b100;
    localparam OP_MUL     = 3'b101;
    localparam OP_CLEAR   = 3'b110;
    localparam OP_DISPLAY = 3'b111;

    wire signed [15:0] operando_a_sinal = operando_a;
    wire signed [15:0] operando_b_sinal = operando_b;

    wire [15:0]        soma      = operando_a + operando_b;
    wire [15:0]        subtracao = operando_a - operando_b;
    wire signed [31:0] produto   = operando_a_sinal * operando_b_sinal;

    always @(*) begin
        resultado = 16'd0;
        overflow  = 1'b0;

        case (opcode)
            OP_LOAD: resultado = operando_b;

            OP_ADD, OP_ADDI: begin
                resultado = soma;
                overflow  = (operando_a[15] == operando_b[15]) &&
                            (soma[15] != operando_a[15]);
            end

            OP_SUB, OP_SUBI: begin
                resultado = subtracao;
                overflow  = (operando_a[15] != operando_b[15]) &&
                            (subtracao[15] != operando_a[15]);
            end

            OP_MUL: begin
                resultado = produto[15:0];
                overflow  = (produto[31:15] != {17{produto[15]}});
            end

            OP_DISPLAY: resultado = operando_a;

            default: resultado = 16'd0;
        endcase
    end

endmodule
