module formatador_lcd (
    input  wire [2:0]   opcode,
    input  wire [3:0]   reg_destino,
    input  wire [15:0]  resultado,
    output wire [127:0] linha1,
    output wire [127:0] linha2
);

    localparam OP_LOAD    = 3'b000;
    localparam OP_ADD     = 3'b001;
    localparam OP_ADDI    = 3'b010;
    localparam OP_SUB     = 3'b011;
    localparam OP_SUBI    = 3'b100;
    localparam OP_MUL     = 3'b101;
    localparam OP_CLEAR   = 3'b110;
    localparam OP_DISPLAY = 3'b111;

    wire        resultado_negativo = resultado[15];
    wire [15:0] resultado_modulo   = resultado_negativo ? (~resultado + 16'd1) : resultado;

    wire [19:0] digitos;
    conversor_bin_bcd u_bcd_resultado (
        .valor_binario (resultado_modulo),
        .digitos_bcd   (digitos)
    );

    function [31:0] nome_operacao;
        input [2:0] op;
        begin
            case (op)
                OP_LOAD:    nome_operacao = "LOAD";
                OP_ADD:     nome_operacao = "ADD ";
                OP_ADDI:    nome_operacao = "ADDI";
                OP_SUB:     nome_operacao = "SUB ";
                OP_SUBI:    nome_operacao = "SUBI";
                OP_MUL:     nome_operacao = "MUL ";
                OP_DISPLAY: nome_operacao = "DPL ";
                default:    nome_operacao = "    ";
            endcase
        end
    endfunction

    function [7:0] caractere_bit;
        input bit_valor;
        begin
            caractere_bit = bit_valor ? "1" : "0";
        end
    endfunction

    function [7:0] caractere_digito;
        input [3:0] digito;
        begin
            caractere_digito = 8'h30 + {4'd0, digito};
        end
    endfunction

    wire [127:0] linha1_normal = { nome_operacao(opcode), "      [",
                                   caractere_bit(reg_destino[3]), caractere_bit(reg_destino[2]),
                                   caractere_bit(reg_destino[1]), caractere_bit(reg_destino[0]), "]" };

    wire [127:0] linha2_normal = { "          ",
                                   (resultado_negativo ? "-" : "+"),
                                   caractere_digito(digitos[19:16]), caractere_digito(digitos[15:12]),
                                   caractere_digito(digitos[11:8]),  caractere_digito(digitos[7:4]),
                                   caractere_digito(digitos[3:0]) };

    assign linha1 = (opcode == OP_CLEAR) ? "CLEAR           " : linha1_normal;
    assign linha2 = (opcode == OP_CLEAR) ? "                " : linha2_normal;

endmodule
