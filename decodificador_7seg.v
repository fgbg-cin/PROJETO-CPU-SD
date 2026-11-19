module decodificador_7seg (
    input  wire [4:0] simbolo,
    output reg  [6:0] segmentos_n
);

    always @(*) begin
        case (simbolo)
            5'd0:    segmentos_n = 7'b1000000;
            5'd1:    segmentos_n = 7'b1111001;
            5'd2:    segmentos_n = 7'b0100100;
            5'd3:    segmentos_n = 7'b0110000;
            5'd4:    segmentos_n = 7'b0011001;
            5'd5:    segmentos_n = 7'b0010010;
            5'd6:    segmentos_n = 7'b0000010;
            5'd7:    segmentos_n = 7'b1111000;
            5'd8:    segmentos_n = 7'b0000000;
            5'd9:    segmentos_n = 7'b0010000;
            5'd10:   segmentos_n = 7'b0001000;
            5'd11:   segmentos_n = 7'b0000011;
            5'd12:   segmentos_n = 7'b1000110;
            5'd13:   segmentos_n = 7'b0100001;
            5'd14:   segmentos_n = 7'b0000110;
            5'd15:   segmentos_n = 7'b0001110;
            5'd17:   segmentos_n = 7'b0111111;
            default: segmentos_n = 7'b1111111;
        endcase
    end

endmodule
