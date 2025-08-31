ORG 0x7C00

_START:
    JMP _BOOT

_DEBUG_STAR_CHECK:
    PUSH AX
    MOV AH, 0x0E
    MOV AL, '*'
    INT 0x10
    POP AX
    RET


_BOOT:
    CALL _DEBUG_STAR_CHECK
    MOV AH, 02H ; read sectors
    CALL _DEBUG_STAR_CHECK
    MOV AL, 1 ; read (1) sectors
    MOV CH, 0 ; cylinder (0)
    MOV CL, 2 ; sector (1)
    MOV DH, 0 ; head (0)
    CALL _DEBUG_STAR_CHECK
    MOV BX, 0x07F0
    MOV ES, BX
    MOV BX, 0x0000
    CALL _DEBUG_STAR_CHECK
    INT 0x13
    CALL _DEBUG_STAR_CHECK
    CMP AH, 0
    JNE _ERRORINBOOT
    CALL _DEBUG_STAR_CHECK
    MOV AX, 0x1000
    JMP 0x7F00

_ERRORINBOOT:
    MOV BH, AH
    MOV AH, 14
    MOV AL, 'H'
    INT 0x10
    MOV AL, 'A'
    INT 0x10
    MOV AL, 'L'
    INT 0x10
    MOV AL, 'T'
    INT 0x10
    MOV AL, '!'
    INT 0x10
    MOV AL, BH
    INT 0x10
    HLT

times 510-($-$$) db 0
dw 0AA55h