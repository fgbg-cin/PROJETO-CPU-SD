module controlador_lcd #(
    parameter CICLOS_PARTIDA     = 1_000_000,
    parameter CICLOS_PULSO_EN    = 50,
    parameter CICLOS_ESPERA_BYTE = 100_000
)(
    input  wire         clk,
    input  wire         sistema_ligado,
    input  wire         pedido_escrita,
    input  wire [127:0] linha1,
    input  wire [127:0] linha2,
    output wire         pronto,
    output reg  [7:0]   LCD_DATA,
    output reg          LCD_RS,
    output wire         LCD_RW,
    output reg          LCD_EN
);

    assign LCD_RW = 1'b0;

    localparam E_BOOT_ESPERA  = 3'd0;
    localparam E_APAGA        = 3'd1;
    localparam E_DESLIGADO    = 3'd2;
    localparam E_ESPERA_LIGAR = 3'd3;
    localparam E_INIT         = 3'd4;
    localparam E_PRONTO       = 3'd5;
    localparam E_ESCREVE      = 3'd6;

    reg [2:0]   estado_lcd     = E_BOOT_ESPERA;
    reg [5:0]   indice_byte    = 6'd0;
    reg [1:0]   fase_envio     = 2'd0;
    reg [21:0]  contador_tempo = 22'd0;
    reg [127:0] copia_linha1   = {16{8'h20}};
    reg [127:0] copia_linha2   = {16{8'h20}};

    assign pronto = (estado_lcd == E_PRONTO);

    initial begin
        LCD_DATA = 8'h00;
        LCD_RS   = 1'b0;
        LCD_EN   = 1'b0;
    end

    reg [7:0] byte_da_vez;
    reg       rs_da_vez;
    reg [5:0] ultimo_indice;

    always @(*) begin
        byte_da_vez   = 8'h00;
        rs_da_vez     = 1'b0;
        ultimo_indice = 6'd0;
        case (estado_lcd)
            E_INIT: begin
                ultimo_indice = 6'd4;
                case (indice_byte)
                    6'd0:    byte_da_vez = 8'h38;
                    6'd1:    byte_da_vez = 8'h38;
                    6'd2:    byte_da_vez = 8'h0C;
                    6'd3:    byte_da_vez = 8'h06;
                    default: byte_da_vez = 8'h01;
                endcase
            end
            E_APAGA: begin
                ultimo_indice = 6'd2;
                case (indice_byte)
                    6'd0:    byte_da_vez = 8'h38;
                    6'd1:    byte_da_vez = 8'h08;
                    default: byte_da_vez = 8'h01;
                endcase
            end
            E_ESCREVE: begin
                ultimo_indice = 6'd33;
                if (indice_byte == 6'd0) begin
                    byte_da_vez = 8'h80;
                end else if (indice_byte <= 6'd16) begin
                    rs_da_vez   = 1'b1;
                    byte_da_vez = copia_linha1[8*(16 - indice_byte) +: 8];
                end else if (indice_byte == 6'd17) begin
                    byte_da_vez = 8'hC0;
                end else begin
                    rs_da_vez   = 1'b1;
                    byte_da_vez = copia_linha2[8*(33 - indice_byte) +: 8];
                end
            end
            default: ;
        endcase
    end

    wire enviando_sequencia = (estado_lcd == E_INIT) || (estado_lcd == E_APAGA) ||
                              (estado_lcd == E_ESCREVE);

    always @(posedge clk) begin
        if (enviando_sequencia) begin
            case (fase_envio)
                2'd0: begin
                    LCD_RS   <= rs_da_vez;
                    LCD_DATA <= byte_da_vez;
                    LCD_EN   <= 1'b0;
                    if (contador_tempo >= CICLOS_PULSO_EN - 1) begin
                        contador_tempo <= 22'd0;
                        fase_envio     <= 2'd1;
                    end else
                        contador_tempo <= contador_tempo + 22'd1;
                end
                2'd1: begin
                    LCD_EN <= 1'b1;
                    if (contador_tempo >= CICLOS_PULSO_EN - 1) begin
                        LCD_EN         <= 1'b0;
                        contador_tempo <= 22'd0;
                        fase_envio     <= 2'd2;
                    end else
                        contador_tempo <= contador_tempo + 22'd1;
                end
                default: begin
                    if (contador_tempo >= CICLOS_ESPERA_BYTE - 1) begin
                        contador_tempo <= 22'd0;
                        fase_envio     <= 2'd0;
                        if (indice_byte == ultimo_indice) begin
                            indice_byte <= 6'd0;
                            if (estado_lcd == E_APAGA) estado_lcd <= E_DESLIGADO;
                            else                       estado_lcd <= E_PRONTO;
                        end else
                            indice_byte <= indice_byte + 6'd1;
                    end else
                        contador_tempo <= contador_tempo + 22'd1;
                end
            endcase
        end
        else begin
            LCD_EN      <= 1'b0;
            fase_envio  <= 2'd0;
            indice_byte <= 6'd0;
            case (estado_lcd)
                E_BOOT_ESPERA: begin
                    if (contador_tempo >= CICLOS_PARTIDA - 1) begin
                        contador_tempo <= 22'd0;
                        estado_lcd     <= E_APAGA;
                    end else
                        contador_tempo <= contador_tempo + 22'd1;
                end
                E_DESLIGADO: begin
                    contador_tempo <= 22'd0;
                    if (sistema_ligado) estado_lcd <= E_ESPERA_LIGAR;
                end
                E_ESPERA_LIGAR: begin
                    if (contador_tempo >= CICLOS_PARTIDA - 1) begin
                        contador_tempo <= 22'd0;
                        estado_lcd     <= E_INIT;
                    end else
                        contador_tempo <= contador_tempo + 22'd1;
                end
                E_PRONTO: begin
                    contador_tempo <= 22'd0;
                    if (!sistema_ligado)
                        estado_lcd <= E_APAGA;
                    else if (pedido_escrita) begin
                        copia_linha1 <= linha1;
                        copia_linha2 <= linha2;
                        estado_lcd   <= E_ESCREVE;
                    end
                end
                default: estado_lcd <= E_DESLIGADO;
            endcase
        end
    end

endmodule
