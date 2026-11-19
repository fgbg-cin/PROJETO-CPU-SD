module botao_debounce #(
    parameter CICLOS_DEBOUNCE = 1_000_000
)(
    input  wire clk,
    input  wire botao_n,
    output reg  pulso_soltou
);

    reg sinc_estagio1 = 1'b1;
    reg sinc_estagio2 = 1'b1;
    always @(posedge clk) begin
        sinc_estagio1 <= botao_n;
        sinc_estagio2 <= sinc_estagio1;
    end

    reg        nivel_estavel         = 1'b1;
    reg [21:0] contador_estabilidade = 22'd0;

    initial pulso_soltou = 1'b0;

    always @(posedge clk) begin
        pulso_soltou <= 1'b0;

        if (sinc_estagio2 == nivel_estavel) begin
            contador_estabilidade <= 22'd0;
        end
        else if (contador_estabilidade >= CICLOS_DEBOUNCE - 1) begin
            nivel_estavel         <= sinc_estagio2;
            contador_estabilidade <= 22'd0;
            if (sinc_estagio2 == 1'b1)
                pulso_soltou <= 1'b1;
        end
        else begin
            contador_estabilidade <= contador_estabilidade + 22'd1;
        end
    end

endmodule
