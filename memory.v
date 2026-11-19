module memory (
    input  wire        clk,
    input  wire        zerar_tudo,
    input  wire        habilita_escrita,
    input  wire [3:0]  endereco_escrita,
    input  wire [15:0] valor_escrita,
    input  wire [3:0]  endereco_leitura_a,
    input  wire [3:0]  endereco_leitura_b,
    output wire [15:0] valor_leitura_a,
    output wire [15:0] valor_leitura_b
);

    reg [15:0] registradores [0:15];

    integer indice;
    initial begin
        for (indice = 0; indice < 16; indice = indice + 1)
            registradores[indice] = 16'd0;
    end

    always @(posedge clk) begin
        if (zerar_tudo) begin
            for (indice = 0; indice < 16; indice = indice + 1)
                registradores[indice] <= 16'd0;
        end
        else if (habilita_escrita) begin
            registradores[endereco_escrita] <= valor_escrita;
        end
    end

    assign valor_leitura_a = registradores[endereco_leitura_a];
    assign valor_leitura_b = registradores[endereco_leitura_b];

endmodule
