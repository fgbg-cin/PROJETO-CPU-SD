module decodificador_instrucao (
    input  wire [17:0] instrucao,
    output wire [2:0]  opcode,
    output wire [3:0]  reg_destino,
    output wire [3:0]  reg_fonte_a,
    output wire [3:0]  reg_fonte_b,
    output wire [15:0] imediato_c2
);

    assign opcode      = instrucao[17:15];
    assign reg_destino = instrucao[14:11];
    assign reg_fonte_a = instrucao[10:7];
    assign reg_fonte_b = instrucao[6:3];

    wire       imediato_negativo = instrucao[6];
    wire [5:0] imediato_modulo   = instrucao[5:0];

    assign imediato_c2 = imediato_negativo ? (16'd0 - {10'd0, imediato_modulo})
                                           : {10'd0, imediato_modulo};

endmodule
