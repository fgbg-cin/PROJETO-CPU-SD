module painel_hex (
    input  wire        sistema_ligado,
    input  wire [17:0] chaves,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    localparam SIMBOLO_APAGADO = 5'd16;
    localparam SIMBOLO_MENOS   = 5'd17;

    wire [2:0] opcode            = chaves[17:15];
    wire [3:0] reg_destino       = chaves[14:11];
    wire [3:0] reg_fonte_a       = chaves[10:7];
    wire [3:0] reg_fonte_b       = chaves[6:3];
    wire       imediato_negativo = chaves[6];
    wire [5:0] imediato_modulo   = chaves[5:0];

    wire usa_destino  = (opcode != 3'b110);
    wire usa_fonte_a  = (opcode == 3'b001) || (opcode == 3'b010) ||
                        (opcode == 3'b011) || (opcode == 3'b100) ||
                        (opcode == 3'b101);
    wire usa_fonte_b  = (opcode == 3'b001) || (opcode == 3'b011);
    wire usa_imediato = (opcode == 3'b000) || (opcode == 3'b010) ||
                        (opcode == 3'b100) || (opcode == 3'b101);

    wire [19:0] imediato_bcd;
    conversor_bin_bcd u_bcd_imediato (
        .valor_binario ({10'd0, imediato_modulo}),
        .digitos_bcd   (imediato_bcd)
    );

    wire [4:0] simbolo7 = sistema_ligado                ? {2'b00, opcode}       : SIMBOLO_APAGADO;
    wire [4:0] simbolo6 = SIMBOLO_APAGADO;
    wire [4:0] simbolo5 = (sistema_ligado && usa_destino) ? {1'b0, reg_destino} : SIMBOLO_APAGADO;
    wire [4:0] simbolo4 = (sistema_ligado && usa_fonte_a) ? {1'b0, reg_fonte_a} : SIMBOLO_APAGADO;
    wire [4:0] simbolo3 = (sistema_ligado && usa_fonte_b) ? {1'b0, reg_fonte_b} : SIMBOLO_APAGADO;
    wire [4:0] simbolo2 = (sistema_ligado && usa_imediato && imediato_negativo) ? SIMBOLO_MENOS : SIMBOLO_APAGADO;
    wire [4:0] simbolo1 = (sistema_ligado && usa_imediato) ? {1'b0, imediato_bcd[7:4]} : SIMBOLO_APAGADO;
    wire [4:0] simbolo0 = (sistema_ligado && usa_imediato) ? {1'b0, imediato_bcd[3:0]} : SIMBOLO_APAGADO;

    decodificador_7seg hex7 (.simbolo(simbolo7), .segmentos_n(HEX7));
    decodificador_7seg hex6 (.simbolo(simbolo6), .segmentos_n(HEX6));
    decodificador_7seg hex5 (.simbolo(simbolo5), .segmentos_n(HEX5));
    decodificador_7seg hex4 (.simbolo(simbolo4), .segmentos_n(HEX4));
    decodificador_7seg hex3 (.simbolo(simbolo3), .segmentos_n(HEX3));
    decodificador_7seg hex2 (.simbolo(simbolo2), .segmentos_n(HEX2));
    decodificador_7seg hex1 (.simbolo(simbolo1), .segmentos_n(HEX1));
    decodificador_7seg hex0 (.simbolo(simbolo0), .segmentos_n(HEX0));

endmodule
