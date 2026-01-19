BITS 16
ORG 0x0000

;DOCUMENTATION: This may be branched into a text file later.

    ;v0.1.1  | LOAD command added that hands control over to the disk in floppy drive two.
    ;V0.1.0b | Command table is now formatted to handle numerous commands. 
    ;V0.1.0  | Now you can execute one, yes ONE command. The capability is here, but certainly not formatted to handle a larger table yet.
    ;V0.0.4  | Input is now properly stored and limited, kernel text can no longer be deleted.
    ;V0.0.3  | Stack redefined for usage in later variants, input buffer defined.
    ;V0.0.2  | Implemented F10 as a special key, changing video mode and launching a demo. This will remain untouched until much later.
    ;V0.0.1b | Reformatted code for attachment to BOOTLOADER.ASM.
    ;V0.0.1  | Added support for Enter and Backspace keys.
    ;V0.0.0  | Added basic text functionality.

;FUNCTIONS AND THEIR PARAMETERS:

    ;_WRITESTR: [(BX, 'STRNAME')], Prints a specified string to the console. Push and pop BX before/after using this or you will regret it.
    ;_BOOTKEY:  [nil], Not necessarily a function, but enters the graphical environment. There will be no way to return to the terminal.

; CONSTANTS

INBUFSIZE EQU 16
%define KERNVER '0.1.1'

; SECTION .TERMINAL

_START:
    MOV AH, 0
    MOV AL, 3
    INT 0x10
    MOV AX, CS
    MOV DS, AX
    MOV SS, AX
    MOV SP, STACK
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
    JMP _INITGRAPHICS  

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
    MOV AH, 02 ; Read Sectors
    MOV AL, 1 ; 1 Sector
    MOV CH, 0 ; C
    MOV CL, 1 ; S
    MOV DH, 0 ; H
    MOV DL, 1 ; Second floppy
    MOV BX, 0x2000
    MOV ES, BX
    MOV BX, 0X0000
    INT 0X13
    JC _LOADFAIL
    JMP 0X2000:0X0000 
_LOADFAIL:
    MOV AX, CS
    MOV ES, AX
    PUSH BX
    MOV BX, NODISK
    CALL _WRITESTR
    POP BX
    RET

_CMDINT:
   CLD
   MOV SI, CMDLIST + 1
   MOV DI, INBUF
_CMDCMP: ; Compares the nth entry of the user input to the command in the table pointed to by SI.
   CMP BYTE [SI], 0xFF ; End of table?
   JE _NOCMD
   CMPSB
   JNE _CMDNXT ; Next command.
   CMP BYTE [SI - 1], 0 ; Full match?
   JNE _CMDCMP
   JMP [SI] 
_CMDNXT:
   LODSB ; Fix pointer address to start of next command.
   CMP AL, 0
   JNE _CMDNXT
   MOV DI, INBUF
   ADD SI, 2
   JMP _CMDCMP
_NOCMD:
    RET

; SECTION .TERMINAL_DATA

INTROMES      db 'BOOT SUCCESSFUL. TERMINAL.', 0
KERNPREFIX    db 'KERNEL*//>', 0
NOCOMM        db 'NO COMMAND', 0x0D, 0x0A, 0
NODISK        db 'NO DISK', 0x0D, 0x0A, 0
INBUF         TIMES (INBUFSIZE + 1) db 0
INPTR         dw 0   
INFSTR        db 'THE KERNEL V', KERNVER, 0x0D, 0x0A, 0

CMDLIST       db 0
TINFO         db 'INFO', 0
INFO          dw _INFO
THANG         db 'HANG', 0
HANG          dw _HANG
LOAD          db 'LOAD', 0
TLOAD         dw _LOAD
END           db 0xFF

; SECTION .GRAPHICS

_INITGRAPHICS:
    MOV AX, 0xA000 ; VRAM Location.
    MOV ES, AX
    MOV AL, 0X00 ; Bit mask.
    JMP _LOOPIT

_LOOPIT:
    MOV DI, 0x0 ; Offset of VRAM to begin.
    MOV CX, 0X9600 ; Amount of times to repeat.
    CLD
    REP STOSB
    INC AL
    JMP _LOOPIT

; SECTION .GRAPHICS_DATA

; SECTION .AUXILARY

_DONOTHING: ; Why is this here?
    JMP _DONOTHING

_RET: ; Useful exit point for conditional returns.
    RET

; SECTION .END

TIMES 512-($-$$) db 0

STACKINIT:
    TIMES 1024 db 0
STACK: