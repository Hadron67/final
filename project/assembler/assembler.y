
%lex {

    < (['\n', '\r']|'\r\n')+ >: [='']
    < ';' [^'\n', '\r']* >: [='']

    < NAME: ['A'-'Z', 'a'-'z', '_', '$']['A'-'Z', 'a'-'z', '0'-'9', '_', '$']* >
    < NUM: ['0'-'9']+ >
    < BRA: '(' >
    < KET: ')' >
    < COMMA: ',' >
    < COLON: ':' >

    < INS_ADD: 'add' >
    < INS_ADDU: 'addu' >
    < INS_SUB: 'sub' >
    < INS_SUBU: 'subu' >
    
}