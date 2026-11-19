`timescale 1ns/1ps
module tb_unidades;
    reg  [2:0]  op;
    reg  [15:0] a, b;
    wire [15:0] r;
    wire        ovf;
    module_alu ula (.opcode(op), .operando_a(a), .operando_b(b), .resultado(r), .overflow(ovf));

    reg  [15:0] bin;
    wire [19:0] bcd;
    conversor_bin_bcd conv (.valor_binario(bin), .digitos_bcd(bcd));

    integer n, erros, esperado, real_bcd, ia, ib;
    integer verdadeiro;

    initial begin
        erros = 0;
        for (n = 0; n < 120000; n = n + 1) begin
            op = $random % 8;
            a  = $random;  b = $random;
            #1;
            ia = $signed(a); ib = $signed(b);
            case (op)
                3'b000:          verdadeiro = ib;
                3'b001, 3'b010:  verdadeiro = ia + ib;
                3'b011, 3'b100:  verdadeiro = ia - ib;
                3'b101:          verdadeiro = ia * ib;
                3'b111:          verdadeiro = ia;
                default:         verdadeiro = 0;
            endcase
            esperado = verdadeiro & 16'hFFFF;
            if (r !== esperado[15:0] ||
                ovf !== ((verdadeiro > 32767) || (verdadeiro < -32768))) begin
                erros = erros + 1;
                if (erros < 10)
                    $display("ULA ERRO op=%b a=%0d b=%0d r=%0d ovf=%b (esperado %0d)",
                             op, ia, ib, $signed(r), ovf, verdadeiro);
            end
        end
        $display("ULA: 120000 casos aleatorios testados, %0d erros", erros);

        erros = 0;
        for (n = 0; n < 65536; n = n + 1) begin
            bin = n; #1;
            real_bcd = bcd[19:16]*10000 + bcd[15:12]*1000 + bcd[11:8]*100 +
                       bcd[7:4]*10 + bcd[3:0];
            if (real_bcd != n) begin
                erros = erros + 1;
                if (erros < 10) $display("BCD ERRO %0d -> %h", n, bcd);
            end
        end
        $display("BCD: 65536 valores testados, %0d erros", erros);
        $finish;
    end
endmodule
