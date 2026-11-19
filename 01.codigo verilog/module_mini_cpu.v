module module_mini_cpu #(
    parameter CICLOS_DEBOUNCE        = 1_000_000,
    parameter LCD_CICLOS_PARTIDA     = 1_000_000,
    parameter LCD_CICLOS_PULSO_EN    = 50,
    parameter LCD_CICLOS_ESPERA_BYTE = 100_000
)(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output wire [7:0]  LCD_DATA,
    output wire        LCD_RS,
    output wire        LCD_RW,
    output wire        LCD_EN,
    output wire        LCD_ON,
    output wire        LCD_BLON,
    output wire [17:0] LEDR,
    output wire [8:0]  LEDG,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3,
    output wire [6:0]  HEX4, HEX5, HEX6, HEX7
);

    wire clk = CLOCK_50;

    localparam OP_LOAD    = 3'b000;
    localparam OP_ADD     = 3'b001;
    localparam OP_ADDI    = 3'b010;
    localparam OP_SUB     = 3'b011;
    localparam OP_SUBI    = 3'b100;
    localparam OP_MUL     = 3'b101;
    localparam OP_CLEAR   = 3'b110;
    localparam OP_DISPLAY = 3'b111;

    localparam S_DESLIGADO  = 3'd0;
    localparam S_ESPERA     = 3'd1;
    localparam S_BUSCA      = 3'd2;
    localparam S_DECODIFICA = 3'd3;
    localparam S_EXECUTA    = 3'd4;
    localparam S_ARMAZENA   = 3'd5;
    localparam S_MOSTRA     = 3'd6;

    wire pulso_ligar, pulso_enviar;

    botao_debounce #(.CICLOS_DEBOUNCE(CICLOS_DEBOUNCE)) u_botao_ligar (
        .clk(clk), .botao_n(KEY[3]), .pulso_soltou(pulso_ligar)
    );
    botao_debounce #(.CICLOS_DEBOUNCE(CICLOS_DEBOUNCE)) u_botao_enviar (
        .clk(clk), .botao_n(KEY[2]), .pulso_soltou(pulso_enviar)
    );

    reg [2:0]   estado            = S_DESLIGADO;
    reg         sistema_ligado    = 1'b0;
    reg         desligar_pendente = 1'b0;
    reg [17:0]  instrucao         = 18'd0;

    reg [2:0]   opcode      = 3'd0;
    reg [3:0]   reg_destino = 4'd0;
    reg [3:0]   reg_fonte_a = 4'd0;
    reg [3:0]   reg_fonte_b = 4'd0;
    reg [15:0]  imediato    = 16'd0;

    reg [15:0]  resultado       = 16'd0;
    reg         overflow_salvo  = 1'b0;

    reg [127:0] texto_linha1  = {16{8'h20}};
    reg [127:0] texto_linha2  = {16{8'h20}};
    reg         lcd_atualizar = 1'b0;
    wire        lcd_pronto;

    wire [2:0]  campo_opcode;
    wire [3:0]  campo_destino, campo_fonte_a, campo_fonte_b;
    wire [15:0] campo_imediato;

    decodificador_instrucao u_decodificador (
        .instrucao   (instrucao),
        .opcode      (campo_opcode),
        .reg_destino (campo_destino),
        .reg_fonte_a (campo_fonte_a),
        .reg_fonte_b (campo_fonte_b),
        .imediato_c2 (campo_imediato)
    );

    wire usa_imediato = (opcode == OP_LOAD) || (opcode == OP_ADDI) ||
                        (opcode == OP_SUBI) || (opcode == OP_MUL);

    wire grava_registrador = (opcode != OP_CLEAR) && (opcode != OP_DISPLAY);

    wire [3:0]  endereco_leitura_a = (opcode == OP_DISPLAY) ? reg_destino : reg_fonte_a;
    wire [3:0]  endereco_leitura_b = reg_fonte_b;
    wire [15:0] valor_reg_a, valor_reg_b;

    wire [15:0] operando_b_ula = usa_imediato ? imediato : valor_reg_b;
    wire [15:0] saida_ula;
    wire        overflow_ula;

    wire mem_habilita_escrita = (estado == S_ARMAZENA) && grava_registrador;
    wire mem_zerar_tudo       = (estado == S_DESLIGADO) ||
                                ((estado == S_ARMAZENA) && (opcode == OP_CLEAR));

    memory u_banco_registradores (
        .clk                (clk),
        .zerar_tudo         (mem_zerar_tudo),
        .habilita_escrita   (mem_habilita_escrita),
        .endereco_escrita   (reg_destino),
        .valor_escrita      (resultado),
        .endereco_leitura_a (endereco_leitura_a),
        .endereco_leitura_b (endereco_leitura_b),
        .valor_leitura_a    (valor_reg_a),
        .valor_leitura_b    (valor_reg_b)
    );

    module_alu u_ula (
        .opcode     (opcode),
        .operando_a (valor_reg_a),
        .operando_b (operando_b_ula),
        .resultado  (saida_ula),
        .overflow   (overflow_ula)
    );

    wire [127:0] linha1_formatada, linha2_formatada;
    formatador_lcd u_formatador_lcd (
        .opcode      (opcode),
        .reg_destino (reg_destino),
        .resultado   (resultado),
        .linha1      (linha1_formatada),
        .linha2      (linha2_formatada)
    );

    controlador_lcd #(
        .CICLOS_PARTIDA     (LCD_CICLOS_PARTIDA),
        .CICLOS_PULSO_EN    (LCD_CICLOS_PULSO_EN),
        .CICLOS_ESPERA_BYTE (LCD_CICLOS_ESPERA_BYTE)
    ) u_controlador_lcd (
        .clk            (clk),
        .sistema_ligado (sistema_ligado),
        .pedido_escrita (lcd_atualizar),
        .linha1         (texto_linha1),
        .linha2         (texto_linha2),
        .pronto         (lcd_pronto),
        .LCD_DATA       (LCD_DATA),
        .LCD_RS         (LCD_RS),
        .LCD_RW         (LCD_RW),
        .LCD_EN         (LCD_EN)
    );

    assign LCD_ON   = 1'b1;
    assign LCD_BLON = 1'b0;

    always @(posedge clk) begin
        lcd_atualizar <= 1'b0;

        if (pulso_ligar && estado != S_DESLIGADO && estado != S_ESPERA)
            desligar_pendente <= 1'b1;

        case (estado)
            S_DESLIGADO: begin
                desligar_pendente <= 1'b0;
                if (pulso_ligar) begin
                    sistema_ligado <= 1'b1;
                    texto_linha1   <= "____      [----]";
                    texto_linha2   <= "          +00000";
                    estado         <= S_MOSTRA;
                end
            end
            S_ESPERA: begin
                if (pulso_ligar || desligar_pendente) begin
                    sistema_ligado    <= 1'b0;
                    desligar_pendente <= 1'b0;
                    estado            <= S_DESLIGADO;
                end
                else if (pulso_enviar) begin
                    estado <= S_BUSCA;
                end
            end
            S_BUSCA: begin
                instrucao <= SW;
                estado    <= S_DECODIFICA;
            end
            S_DECODIFICA: begin
                opcode      <= campo_opcode;
                reg_destino <= campo_destino;
                reg_fonte_a <= campo_fonte_a;
                reg_fonte_b <= campo_fonte_b;
                imediato    <= campo_imediato;
                estado      <= S_EXECUTA;
            end
            S_EXECUTA: begin
                resultado      <= saida_ula;
                overflow_salvo <= overflow_ula;
                estado         <= S_ARMAZENA;
            end
            S_ARMAZENA: begin
                texto_linha1 <= linha1_formatada;
                texto_linha2 <= linha2_formatada;
                estado       <= S_MOSTRA;
            end
            S_MOSTRA: begin
                if (lcd_pronto) begin
                    lcd_atualizar <= 1'b1;
                    estado        <= S_ESPERA;
                end
            end
            default: estado <= S_DESLIGADO;
        endcase
    end

    assign LEDR      = SW;
    assign LEDG[0]   = sistema_ligado;
    assign LEDG[1]   = (estado == S_ESPERA);
    assign LEDG[2]   = overflow_salvo;
    assign LEDG[8:3] = 6'd0;

    painel_hex u_painel_hex (
        .sistema_ligado (sistema_ligado),
        .chaves         (SW),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6), .HEX7(HEX7)
    );

endmodule
