BITS 16
ORG 0x7C00

; section .text

_START:
    MOV [BOOTID], DL
    MOV AH, 14
    MOV AL, 'A'
    INT 0X10
    MOV AH, 02 ; Read
    MOV AL, 6 ; 4 Sectors (3K)
    MOV CH, 0 ; From Cylinder 0
    MOV CL, 2 ; Starting from Sector 2 (1)
    MOV DH, 0 ; On Head 0
    MOV DL, [BOOTID] ; The ID, Y'know
    MOV BX, 0x1000
    MOV ES, BX ; Address
    MOV BX, 0X0000 ; Offset
    INT 0X13
    JMP 0X1000:0X0000 ; Greatly Insane

; section .data
BOOTID DB 0
times 510-($-$$) db 0
dw 0AA55h