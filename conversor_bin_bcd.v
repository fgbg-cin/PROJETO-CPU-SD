module conversor_bin_bcd (
    input  wire [15:0] valor_binario,
    output reg  [19:0] digitos_bcd
);

    reg [35:0] deslocador;
    integer iteracao, digito;

    always @(*) begin
        deslocador = {20'd0, valor_binario};
        for (iteracao = 0; iteracao < 16; iteracao = iteracao + 1) begin
            for (digito = 0; digito < 5; digito = digito + 1) begin
                if (deslocador[16 + 4*digito +: 4] >= 4'd5)
                    deslocador[16 + 4*digito +: 4] = deslocador[16 + 4*digito +: 4] + 4'd3;
            end
            deslocador = deslocador << 1;
        end
        digitos_bcd = deslocador[35:16];
    end

endmodule
