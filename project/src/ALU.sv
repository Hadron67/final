package ALUOptr;
    typedef enum logic [4:0] {
        NONE,
        PLUS,
        PLUSU,
        MINUS,
        MINUSU,
        TIMES,
        TIMESU,
        DIV,
        DIVU,
        AND,
        OR,
        XOR,
        NOR,
        EQ,
        NE,
        LT,
        LTU,
        LS,
        RS,
        RSA
    } ALUOptr_t;
endpackage

import ALUOptr::*;

module ALU(
    input ALUOptr_t optr,
    input wire overflowTrap,
    input wire [31:0] A,
    input wire [31:0] B,

    output wire z,
    output wire overflow,
    output logic [63:0] result
);
    always @* begin
        case (optr) 
            PLUS:    result = A + B;
            MINUS:   result =  A - B;
            TIMESU:  result = A * B ;
            TIMES:   result = $signed(A) * $signed(B);
            // XXX: division operations cost 2000+ logic elements!
            // ALUOP_DIVU: result = {A / B, A % B} ;
            // ALUOP_DIV: result = {$signed(A) / $signed(B), $signed(A) % $signed(B)};
            AND:     result = A & B;
            OR:      result = A | B;
            XOR:     result = A ^ B;
            NOR:     result = ~(A | B);
            LTU:     result = A < B;
            LT:      result = $signed(A) < $signed(B);
            LS:      result = A << B;
            RS:      result = A >> B;
            RSA:     result = A >>> B;
            EQ:      result = A == B ? 1'b1 : 1'b0;
            NE:      result = A != B ? 1'b1 : 1'b0;
            default: result = 64'hxxxxxxxx;
        endcase
    end

    assign z = ~|result;

    assign overflow = overflowTrap ? A[31] & B[31] & ~result[31] | ~A[31] & ~B[31] & result[31] : 1'bx;

endmodule // AL: