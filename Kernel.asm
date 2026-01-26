BITS 16
ORG 0x0000

; CONSTANTS

INBUFSIZE EQU 32
%define KERNVER '0.1.2'

; SECTION .TERMINAL

_START:
    MOV AH, 0
    MOV AL, 3
    INT 0x10
    MOV AX, CS
    MOV DS, AX
    MOV SS, AX
    MOV SP, STACK
_INTINIT:
    CLI 
    XOR AX, AX
    MOV ES, AX
    MOV WORD [ES:0x100], _WRITEGRAPH ; 0x40
    MOV WORD [ES:0X102], 0x1000 ; My interrupt now
    STI
    MOV AX, CS
    MOV ES, AX
_BEGIN:
    MOV BX, INTROMES
    CALL _WRITESTR
    JMP _ENTERPRESSED

_READ:
    MOV AH, 00H
    INT 0x16
    CMP AH, 0x1C ; Enter Scan Code
    JE _ENTERPRESSED
    CMP AH, 0x0E ; Backspace Scan Code
    JE _BACKSPACEPRESSED
    CMP AH, 0x44 ; F10 Scan Code
    JE _BOOTKEY
    CMP AL, 'a' ; Is input capital (I like capital)
    JB _READ2
    CMP AL, 'z'
    JA _READ2
    SUB AL, 0x20 ; No? Well it is now.
_READ2:
    CMP AL, 0
    JE _READ
    MOV BX, [INPTR]
    CMP BX, INBUFSIZE ; Is buffer full?
    JAE _READ
    JMP _WRITE

_WRITE:
    MOV [INBUF + BX], AL ; Powerhousing
    INC WORD [INPTR]
    MOV AH, 0Eh
    INT 0x10
    JMP _READ

_WRITESTR:
    MOV AL, [BX]
    MOV AH, 0EH
    CMP AL, 0
    JE _RET
    INT 0x10
    INC BX
    JMP _WRITESTR

_ENTERPRESSED:
    MOV BX, [INPTR]
    MOV BYTE [INBUF + BX], 0
    MOV WORD [INPTR], 0
    MOV AH, 14
    MOV AL, 0x0D
    INT 0x10
    MOV AL, 0x0A
    INT 0x10
    CALL _CMDINT
    PUSH BX
    MOV BX, KERNPREFIX
    CALL _WRITESTR
    POP BX
    JMP _READ

_BACKSPACEPRESSED:
    MOV BX, [INPTR]
    CMP BX, 0
    JE _READ
    DEC WORD [INPTR]
    MOV AH, 14
    INT 0x10
    MOV AL, 0x20
    INT 0x10
    MOV AL, 0x08
    INT 0x10
    JMP _READ

_BOOTKEY:
    MOV AH, 0X0
    MOV AL, 0X11 ; Monochrome VGA
    INT 0X10
    JMP _GRAPHCLR  

_INFO:
    PUSH BX
    MOV BX, INFSTR
    CALL _WRITESTR
    POP BX
    RET

_HANG:
    MOV BX, NOCOMM
    CALL _WRITESTR
    JMP _HANG ; Hey, a state without exit mustn't remain efficient.

_LOAD:
    PUSH ES
    XOR AH, AH ; Reset Drive Status
    MOV DL, 1 ; Second floppy
    INT 0x13
    MOV AH, 02 ; Read Sectors
    MOV AL, 1 ; 1 Sector
    MOV CH, 0 ; C
    MOV CL, 1 ; S
    MOV DH, 0 ; H
    MOV BX, 0x2000
    MOV ES, BX
    MOV BX, 0X0000
    INT 0X13
    POP ES
    JC _LOADFAIL
    MOV BYTE [DISKLOADED], 1
    RET
_LOADFAIL:
    MOV AX, CS
    MOV ES, AX
    PUSH BX
    MOV BX, NODISK
    CALL _WRITESTR
    POP BX
    MOV BYTE [DISKLOADED], 0
    RET

_RUN: 
    CMP BYTE [DISKLOADED], 1
    JE _HANDOFF
    PUSH BX
    MOV BX, NODISK
    CALL _WRITESTR
    POP BX
    RET
_HANDOFF:
    JMP 0x2000:0x0000

_LOOK: ; Setup registers and confirm a parameter is provided.
    PUSH BX
    MOV SI, DX
    MOV BYTE [SI + 4], 0
    CMP BYTE [SI], 0
    JE _LOOKFAIL
    XOR DX, DX
    XOR AX, AX
    XOR BX, BX
    MOV CX, 8
_LOOKCMP: ; Checks with each hexadecimal to ensure correctness.
    LODSB
    CMP AL, 0
    JE _LOOKPRINT
    CMP AL, '0'
    JB _LOOKFAIL
    CMP AL, '9'
    JBE _LOOKCONV
    CMP AL, 'A'
    JB _LOOKFAIL
    CMP AL, 'F'
    JA _LOOKFAIL
_LOOKCONV: ; Convert to raw counterpart.
    CMP AL, 'A'
    JB _LOOKNUM
    SUB AL, 0x37
    JMP _LOOKSTORE
_LOOKNUM: ; Ditto.
    SUB AL, 0x30
_LOOKSTORE: ; Store the nibble in DX and open room for another; check if input is done. 
    SAL DX, 4
    OR DL, AL
    CMP BYTE [SI], 0
    JE _LOOKPRINT
    JMP _LOOKCMP
_LOOKPRINT: ; Write the value of the two nibbles stored at the constructed memory address.
    MOV AH, 0xE
    MOV SI, DX
    MOV BL, [SI]
    PUSH BX
    AND BL, 0xF0
    ROL BL, 4
    MOV AL, [HEXTABLE + BX]
    INT 0x10
    POP BX
    AND BL, 0x0F
    MOV AL, [HEXTABLE + BX]
    INT 0x10
    MOV AL, 0x20
    INT 0x10 
    DEC CX
    CMP CX, 0
    JE _LOOKEND
    INC DX
    JMP _LOOKPRINT
_LOOKEND:
    MOV BX, INDENT
    CALL _WRITESTR
    POP BX
    RET
_LOOKFAIL:
    MOV BX, COMMFAIL
    CALL _WRITESTR
    POP BX
    RET

_READCMD:
    RET

_CMDINT: ; Setup pointers.
   CLD
   MOV SI, CMDLIST + 1
   MOV DI, INBUF
_CMDTOK: ; Separate command from arguments.
   MOV AL, [DI]
   CMP AL, 0x00
   JE _CMDFIX
   CMP AL, 0x20
   JNE _SKIPCH
   MOV BYTE [DI], 0x00
   LEA DX, [DI + 1] ; Store parameter 1 in DX.
_SKIPCH:
    INC DI
    JMP _CMDTOK
_CMDFIX:
   MOV DI, INBUF
_CMDCMP: ; Compares the nth entry of the user input to the command in the table pointed to by SI.
   CMP BYTE [SI], 0xFF ; End of table?
   JE _NOCMD
   CMPSB
   JNE _CMDNXT ; Next command.
   CMP BYTE [SI - 1], 0 ; Full match?
   JNE _CMDCMP
   JMP [SI] 
_CMDNXT: ; Fixes pointer address to start of next command.
   LODSB 
   CMP AL, 0
   JNE _CMDNXT
   MOV DI, INBUF
   ADD SI, 2
   JMP _CMDCMP
_NOCMD:
    RET

; SECTION .TERMINAL_DATA

DISKLOADED    db 0 ; Set to 1 when disk data is confirmed in memory, and 0 when not.
INTROMES      db 'BOOT SUCCESS. TERMINAL.', 0
KERNPREFIX    db 'KERNEL*//>', 0
NOCOMM        db '?', 0x0D, 0x0A, 0
COMMFAIL      db '*?', 0x0D, 0x0A, 0
NODISK        db 'NO DISK', 0x0D, 0x0A, 0
INDENT        db 0x0D, 0x0A, 0
INBUF         TIMES (INBUFSIZE + 1) db 0
INPTR         dw 0   
INFSTR        db 'THE KERNEL V', KERNVER, 0x0D, 0x0A, 0
HEXTABLE      db '0123456789ABCDEF', 0

CMDLIST:
                  db 0
    INFO          db 'INFO', 0
                  dw _INFO
    HANG          db 'HANG', 0
                  dw _HANG
    LOAD          db 'LOAD', 0
                  dw _LOAD
    RUN           db 'RUN', 0
                  dw _RUN
    LOOK          db 'LOOK', 0
                  dw _LOOK
    READCMD       db 'READ', 0
                  dw _READCMD
    END           db 0xFF

; SECTION .GRAPHICS

_GRAPHCLR:
    MOV AX, 0xA000 ; VRAM Location.
    MOV ES, AX
    XOR DI, DI
    MOV AL, 0xFF
    MOV CX, 0x9600
    REP STOSB
_INITGRAPHICS:
    MOV SI, LETTERTEST ; Bit mask.
    MOV DI, 0x28 ; Offset of VRAM to begin.
    INT 0x40
    JMP _FREEZE

; SECTION .GRAPHICS_DATA

LETTERTEST:
     db 00H,18H,24H,24H,3CH,24H,24H,00H

; SECTION .AUXILARY

_RET: ; Useful exit point for conditional returns.
    RET

_FREEZE: ; NOP
    JMP _FREEZE


; SECTION .INTERRUPTS

_WRITEGRAPH: ; 0x40
    PUSH CX
    PUSH AX
    PUSH DI
    MOV CX, 8
_WGLOOP:
    LODSB
    MOV AH, [ES:DI]
    XOR AH, AL
    MOV [ES:DI], AH
    DEC CX
    JNZ _WGCONT
_WGEND:
    POP DI
    POP AX
    POP CX
    IRET
_WGCONT:
    ADD DI, 80
    JMP _WGLOOP

; SECTION .END

TIMES 1024-($-$$) db 0

STACKINIT:
    TIMES 1024 db 0
STACK: