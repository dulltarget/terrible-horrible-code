ORG 0x7F00

;FUNCTIONS AND THEIR PARAMETERS:
    ;_WRITESTR: [(AH,0EH), (BX, 'STRNAME')], Prints a specified string to the console.



section .data

KernelPrefix db 'KERNEL*//>', 0

section .text

_START:
    JMP _READ


_READ:
    MOV AH, 0EH
    MOV BX, KernelPrefix
    CALL _WRITESTR
    MOV AH, 00H
    INT 0x16
    CMP AH, 0x1C ;Enter ASCII
    JE _ENTERPRESSED
    CMP AH, 0x0E ;Backspace ASCII
    JE _BACKSPACEPRESSED
    JMP _WRITE

_WRITE:
    MOV AH, 14
    INT 0x10
    JMP _READ

_WRITESTR:
    MOV AL, [BX]
    CMP AL, 0
    JE _RET
    INT 0x10
    INC BX
    JMP _WRITESTR

_ENTERPRESSED:
    MOV AH, 14
    MOV AL, 0x0D
    INT 0x10
    MOV AL, 0x0A
    INT 0x10
    JMP _READ

_RET:
    RET ;RET

_BACKSPACEPRESSED:
    MOV AH, 14
    INT 0x10
    MOV AL, 0x20
    INT 0x10
    MOV AL, 0x08
    INT 0x10
    JMP _READ