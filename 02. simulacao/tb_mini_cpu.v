`timescale 1ns/1ps
module tb_mini_cpu;

    reg         clk = 0;
    reg  [3:0]  KEY = 4'b1111;
    reg  [17:0] SW  = 18'd0;
    wire [7:0]  LCD_DATA;
    wire        LCD_RS, LCD_RW, LCD_EN, LCD_ON, LCD_BLON;
    wire [17:0] LEDR;
    wire [8:0]  LEDG;
    wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

    always #10 clk = ~clk;

    module_mini_cpu #(
        .CICLOS_DEBOUNCE(8),
        .LCD_CICLOS_PARTIDA(40),
        .LCD_CICLOS_PULSO_EN(4),
        .LCD_CICLOS_ESPERA_BYTE(10)
    ) dut (
        .CLOCK_50(clk), .KEY(KEY), .SW(SW),
        .LCD_DATA(LCD_DATA), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN), .LCD_ON(LCD_ON), .LCD_BLON(LCD_BLON),
        .LEDR(LEDR), .LEDG(LEDG),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6), .HEX7(HEX7)
    );

    function [7:0] le7;
        input [6:0] g;
        case (g)
            7'b1000000: le7 = "0";  7'b1111001: le7 = "1";
            7'b0100100: le7 = "2";  7'b0110000: le7 = "3";
            7'b0011001: le7 = "4";  7'b0010010: le7 = "5";
            7'b0000010: le7 = "6";  7'b1111000: le7 = "7";
            7'b0000000: le7 = "8";  7'b0010000: le7 = "9";
            7'b0001000: le7 = "A";  7'b0000011: le7 = "b";
            7'b1000110: le7 = "C";  7'b0100001: le7 = "d";
            7'b0000110: le7 = "E";  7'b0001110: le7 = "F";
            7'b0111111: le7 = "-";  7'b1111111: le7 = " ";
            default:    le7 = "?";
        endcase
    endfunction
    wire [63:0] hex_txt = {le7(HEX7), le7(HEX6), le7(HEX5), le7(HEX4),
                           le7(HEX3), le7(HEX2), le7(HEX1), le7(HEX0)};

    reg [7:0] ddram [0:127];
    reg [6:0] cursor = 0;
    reg       display_on = 0;
    integer   k;
    initial for (k = 0; k < 128; k = k + 1) ddram[k] = 8'h20;

    always @(negedge LCD_EN) begin
        if (LCD_RS == 1'b0) begin
            if (LCD_DATA == 8'h01) begin
                for (k = 0; k < 128; k = k + 1) ddram[k] = 8'h20;
                cursor = 0;
            end
            else if (LCD_DATA[7])
                cursor = LCD_DATA[6:0];
            else if (LCD_DATA[7:3] == 5'b00001)
                display_on = LCD_DATA[2];
        end else begin
            ddram[cursor] = LCD_DATA;
            cursor = cursor + 1;
        end
    end

    function [127:0] tela;
        input integer linha;
        integer c;
        begin
            for (c = 0; c < 16; c = c + 1)
                tela[8*(15-c) +: 8] = display_on ?
                    ddram[(linha == 1 ? 0 : 64) + c] : 8'h20;
        end
    endfunction

    task mostra_lcd;
        begin
            $display("        +----------------+");
            $display("        |%s|", tela(1));
            $display("        |%s|", tela(2));
            $display("        +----------------+");
        end
    endtask

    integer passou = 0, falhou = 0;

    task confere;
        input [127:0] l1, l2;
        input [8*40-1:0] nome;
        begin
            if (tela(1) === l1 && tela(2) === l2) begin
                passou = passou + 1;
                $display("[OK]    %0s", nome);
            end else begin
                falhou = falhou + 1;
                $display("[FALHA] %0s", nome);
                $display("        esperado |%s|", l1);
                $display("                 |%s|", l2);
                $display("        obtido:");
            end
            mostra_lcd;
        end
    endtask

    task confere_hex;
        input [63:0] esperado;
        input [8*40-1:0] nome;
        begin
            #1;
            if (hex_txt === esperado) begin
                passou = passou + 1;
                $display("[OK]    %0s   HEX7..0 = [%s]", nome, hex_txt);
            end else begin
                falhou = falhou + 1;
                $display("[FALHA] %0s   HEX7..0 = [%s] esperado [%s]", nome, hex_txt, esperado);
            end
        end
    endtask

    task clica;
        input integer qual;
        begin
            KEY[qual] = 1'b0;
            repeat (40) @(posedge clk);
            KEY[qual] = 1'b1;
            repeat (40) @(posedge clk);
        end
    endtask

    task espera_fim;
        reg ok;
        begin
            repeat (20) @(posedge clk);
            ok = 0;
            while (!ok) begin
                wait (dut.estado == 3'd1 && dut.u_controlador_lcd.estado_lcd == 3'd5);
                repeat (5) @(posedge clk);
                ok = (dut.estado == 3'd1 && dut.u_controlador_lcd.estado_lcd == 3'd5);
            end
        end
    endtask

    task espera_desligar;
        begin
            repeat (20) @(posedge clk);
            wait (dut.estado == 3'd0 && dut.u_controlador_lcd.estado_lcd == 3'd2);
            repeat (5) @(posedge clk);
        end
    endtask

    function [17:0] I_RR;
        input [2:0] op; input [3:0] d, s1, s2;
        I_RR = {op, d, s1, s2, 3'b000};
    endfunction
    function [6:0] SM;
        input integer imm;
        integer m;
        begin
            m  = (imm < 0) ? -imm : imm;
            SM = {(imm < 0) ? 1'b1 : 1'b0, m[5:0]};
        end
    endfunction
    function [17:0] I_RI;
        input [2:0] op; input [3:0] d, s1; input integer imm;
        I_RI = {op, d, s1, SM(imm)};
    endfunction
    function [17:0] I_LOAD;
        input [3:0] d; input integer imm;
        I_LOAD = {3'b000, d, 4'b0000, SM(imm)};
    endfunction
    function [17:0] I_ESP;
        input [2:0] op; input [3:0] r;
        I_ESP = {op, r, 11'd0};
    endfunction

    task executa;
        input [17:0] instrucao;
        input [8*40-1:0] texto;
        begin
            SW = instrucao;
            $display("\n>>> %0s   (SW = %b_%b_%b_%b_%b)", texto,
                     instrucao[17:15], instrucao[14:11], instrucao[10:7],
                     instrucao[6], instrucao[5:0]);
            clica(2);
            espera_fim;
        end
    endtask

    localparam LOAD=3'b000, ADD=3'b001, ADDI=3'b010, SUB=3'b011,
               SUBI=3'b100, MUL=3'b101, CLEAR=3'b110, DISPLAY=3'b111;

    initial begin
        $dumpfile("mini_cpu.vcd");
        $dumpvars(0, tb_mini_cpu);

        $display("\n================ TESTE DA MINI-CPU ================");
        repeat (300) @(posedge clk);

        $display("\n>>> Sistema desligado; aperta ENVIAR (deve ser ignorado)");
        SW = I_LOAD(4'd1, 5);
        clica(2);
        repeat (300) @(posedge clk);
        confere("                ", "                ",
                "1. desligado: display apagado");
        confere_hex("        ", "1b. desligado: displays HEX apagados");
        if (dut.u_banco_registradores.registradores[1] !== 16'd0) begin
            falhou = falhou + 1; $display("[FALHA] R1 mudou com o sistema desligado!");
        end else begin
            passou = passou + 1; $display("[OK]    R1 continua 0 (instrucao ignorada)");
        end

        $display("\n>>> Segura LIGAR apertado (nada deve acontecer ainda)");
        KEY[3] = 1'b0;
        repeat (400) @(posedge clk);
        if (dut.sistema_ligado == 1'b0) begin
            passou = passou + 1; $display("[OK]    com o botao apertado continua desligado");
        end else begin
            falhou = falhou + 1; $display("[FALHA] ligou antes de soltar o botao");
        end
        KEY[3] = 1'b1;
        espera_fim;
        confere("____      [----]", "          +00000",
                "2. ligar: tela inicial");

        SW = I_RI(ADDI, 4'd3, 4'd1, -5);
        confere_hex("2 31 -05", "2b. HEX mostra ADDI R3,R1,-5");
        SW = I_RR(ADD, 4'd10, 4'd11, 4'd12);
        confere_hex("1 AbC   ", "2c. HEX mostra ADD R10,R11,R12");
        SW = I_LOAD(4'd2, 12);
        confere_hex("0 2   12", "2d. HEX mostra LOAD R2,12");
        SW = I_ESP(DISPLAY, 4'd15);
        confere_hex("7 F     ", "2e. HEX mostra DISPLAY R15");
        SW = I_ESP(CLEAR, 4'd0);
        confere_hex("6       ", "2f. HEX mostra CLEAR");

        executa(I_LOAD(4'd2, 12), "LOAD R2, 12");
        confere("LOAD      [0010]", "          +00012", "3. LOAD R2,12");

        executa(I_RR(ADD, 4'd1, 4'd0, 4'd2), "ADD R1, R0, R2");
        confere("ADD       [0001]", "          +00012", "4. ADD R1,R0,R2 (exemplo do PDF)");

        executa(I_RI(ADDI, 4'd3, 4'd1, 5), "ADDI R3, R1, 5");
        confere("ADDI      [0011]", "          +00017", "5. ADDI R3,R1,5");

        executa(I_RI(SUBI, 4'd4, 4'd2, 20), "SUBI R4, R2, 20");
        confere("SUBI      [0100]", "          -00008", "6. SUBI R4,R2,20 = -8");

        executa(I_RR(SUB, 4'd5, 4'd4, 4'd3), "SUB R5, R4, R3");
        confere("SUB       [0101]", "          -00025", "7. SUB R5,R4,R3 = -25");

        executa(I_RI(MUL, 4'd6, 4'd5, -3), "MUL R6, R5, -3");
        confere("MUL       [0110]", "          +00075", "8. MUL R6,R5,-3 = 75");

        executa(I_RI(ADDI, 4'd7, 4'd0, -63), "ADDI R7, R0, -63");
        confere("ADDI      [0111]", "          -00063", "9. ADDI com imediato negativo");

        executa(I_LOAD(4'd8, 63), "LOAD R8, 63");
        executa(I_RI(MUL, 4'd9, 4'd8, 63), "MUL R9, R8, 63");
        confere("MUL       [1001]", "          +03969", "10. MUL R9 = 3969");
        executa(I_RI(MUL, 4'd10, 4'd9, 63), "MUL R10, R9, 63 (overflow)");
        confere("MUL       [1010]", "          -12097", "11. MUL com overflow (250047 -> -12097)");
        if (LEDG[2]) begin passou = passou + 1; $display("[OK]    LED de overflow aceso"); end
        else begin falhou = falhou + 1; $display("[FALHA] LED de overflow apagado"); end

        executa(I_ESP(DISPLAY, 4'd2), "DISPLAY R2");
        confere("DPL       [0010]", "          +00012", "12. DISPLAY R2 (exemplo do PDF)");

        executa(I_ESP(DISPLAY, 4'd15), "DISPLAY R15");
        confere("DPL       [1111]", "          +00000", "13. DISPLAY R15 (nunca escrito)");

        executa(I_ESP(CLEAR, 4'd0), "CLEAR");
        confere("CLEAR           ", "                ", "14. CLEAR mostra so o nome");
        executa(I_ESP(DISPLAY, 4'd5), "DISPLAY R5 (apos CLEAR)");
        confere("DPL       [0101]", "          +00000", "15. CLEAR zerou R5");

        executa(I_LOAD(4'd1, 0), "LOAD R1, 0");
        SW = I_RI(ADDI, 4'd1, 4'd1, 1);
        $display("\n>>> ADDI R1, R1, 1 com botao TREPIDANDO");
        repeat (3) begin
            KEY[2] = 0; repeat (3) @(posedge clk);
            KEY[2] = 1; repeat (3) @(posedge clk);
        end
        KEY[2] = 0; repeat (40) @(posedge clk);
        repeat (3) begin
            KEY[2] = 1; repeat (3) @(posedge clk);
            KEY[2] = 0; repeat (3) @(posedge clk);
        end
        KEY[2] = 1;
        espera_fim;
        repeat (200) @(posedge clk);
        confere("ADDI      [0001]", "          +00001", "16. debounce: executou 1 vez so");

        executa(I_LOAD(4'd1, 32), "LOAD R1, 32");
        executa(I_RI(MUL, 4'd1, 4'd1, 32), "MUL R1, R1, 32 (=1024)");
        executa(I_RI(MUL, 4'd2, 4'd1, 32), "MUL R2, R1, 32 (=32768 -> -32768)");
        confere("MUL       [0010]", "          -32768", "16b. limite -32768 aparece certo");
        executa(I_RI(SUBI, 4'd3, 4'd2, 1), "SUBI R3, R2, 1 (-32769 -> +32767)");
        confere("SUBI      [0011]", "          +32767", "16c. SUBI com overflow vira +32767");

        $display("\n>>> LOAD R4,7 e logo depois ADDI R5,R4,1 (LCD ainda ocupado)");
        SW = I_LOAD(4'd4, 7);          clica(2);
        SW = I_RI(ADDI, 4'd5, 4'd4, 1); clica(2);
        espera_fim;
        confere("ADDI      [0101]", "          +00008", "16d. duas instrucoes seguidas executam");
        if (dut.u_banco_registradores.registradores[4] === 16'd7) begin
            passou = passou + 1; $display("[OK]    R4 = 7 tambem foi gravado");
        end else begin
            falhou = falhou + 1; $display("[FALHA] R4 = %0d", dut.u_banco_registradores.registradores[4]);
        end

        executa(I_LOAD(4'd15, 33), "LOAD R15, 33");
        $display("\n>>> Aperta LIGAR para DESLIGAR");
        clica(3);
        espera_desligar;
        confere("                ", "                ", "17. desligar: display apagado");
        if (dut.u_banco_registradores.registradores[15] === 16'd0 && dut.u_banco_registradores.registradores[2] === 16'd0) begin
            passou = passou + 1; $display("[OK]    registradores zerados ao desligar");
        end else begin
            falhou = falhou + 1; $display("[FALHA] registradores nao foram zerados");
        end
        confere_hex("        ", "17b. desligado: displays HEX apagados");

        $display("\n>>> Liga de novo e mostra R15");
        clica(3);
        espera_fim;
        confere("____      [----]", "          +00000", "18. religar: tela inicial");
        executa(I_ESP(DISPLAY, 4'd15), "DISPLAY R15");
        confere("DPL       [1111]", "          +00000", "19. R15 voltou zerado");

        $display("\n================ RESULTADO ================");
        $display("   %0d verificacoes OK, %0d falhas", passou, falhou);
        $display("============================================\n");
        $finish;
    end

    initial begin
        #50_000_000;
        $display("TIMEOUT!");
        $finish;
    end

endmodule
