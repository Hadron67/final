`include "ALUOp.vh"

module ALU(
    input wire `ALUOP_T optr,
    input wire overflowTrap,
    input wire [31:0] A,
    input wire [31:0] B,

    output wire z,
    output wire overflow,
    output reg [63:0] result
);
    always @* begin
        case (optr) 
            `ALUOP_PLUS:    result = A + B;
            `ALUOP_MINUS:   result =  A - B;
            `ALUOP_TIMESU:  result = A * B ;
            `ALUOP_TIMES:   result = $signed(A) * $signed(B);
            // XXX: division operations cost 2000+ logic elements!
            // ALUOP_DIVU: result = {A / B, A % B} ;
            // ALUOP_DIV: result = {$signed(A) / $signed(B), $signed(A) % $signed(B)};
            `ALUOP_AND:     result = A & B;
            `ALUOP_OR:      result = A | B;
            `ALUOP_XOR:     result = A ^ B;
            `ALUOP_NOR:     result = ~(A | B);
            `ALUOP_LTU:     result = A < B;
            `ALUOP_LT:      result = $signed(A) < $signed(B);
            `ALUOP_LS:      result = A << B;
            `ALUOP_RS:      result = A >> B;
            `ALUOP_RSA:     result = A >>> B;
            `ALUOP_EQ:      result = A == B ? 1'b1 : 1'b0;
            `ALUOP_NE:      result = A != B ? 1'b1 : 1'b0;
            default: result = 64'hxxxxxxxx;
        endcase
    end

    assign z = ~|result;

    assign overflow = overflowTrap ? A[31] & B[31] & ~result[31] | ~A[31] & ~B[31] & result[31] : 1'bx;

endmodule // AL: