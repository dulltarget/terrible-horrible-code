BITS 16
ORG 0x0000

;DOCUMENTATION: This may be branched into a text file later.

    ;V0.1.0a | Now you can execute one, yes ONE command. The capability is here, but certainly not formatted to handle a larger table yet. 0.1.0b will take care of this.
    ;V0.0.4  | Input is now properly stored and limited, kernel text can no longer be deleted.
    ;V0.0.3  | Stack redefined for usage in later variants, input buffer defined.
    ;V0.0.2  | Implemented F10 as a special key, changing video mode and launching a demo. This will remain untouched until much later.
    ;V0.0.1b | Reformatted code for attachment to BOOTLOADER.ASM.
    ;V0.0.1  | Added support for Enter and Backspace keys.
    ;V0.0.0  | Added basic text functionality.

;FUNCTIONS AND THEIR PARAMETERS:

    ;_WRITESTR: [(BX, 'STRNAME')], Prints a specified string to the console. Push and pop BX before/after using this or you will regret it.
    ;_BOOTKEY:  [nil], Not necessarily a function, but enters the graphical environment. There will be no way to return to the terminal.

; Magic Destroyer MAGIC_DESTROYER_VERSION (constants)

INBUFSIZE EQU 16
%define KERNVER    '0.1.0a'

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

_CMDINT:
   MOV SI, CMDLIST + 1
   MOV DI, INBUF
_CMDCMP: ; Compares the nth entry of the user input to the command in the table pointed to by SI.
   CMPSB
   JNE _CMDNXT
   CMP BYTE [SI - 1], 0
   JNE _CMDCMP
   JMP [SI] 
_CMDNXT:
   RET ; PLACEHOLDER FOR 0.1.0B!
    
; SECTION .TERMINAL_DATA

INTROMES   db 'BOOT SUCCESSFUL. TERMINAL.', 0
KERNPREFIX    db 'KERNEL*//>', 0
INBUF   TIMES (INBUFSIZE + 1) db 0
INPTR   dw 0   
INFSTR   db 'THE KERNEL V', KERNVER, 0x0D, 0x0A, 0

CMDLIST   db 0
TINFO   db 'INFO', 0
INFO   dw _INFO

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

_DONOTHING: ; Placeholder for a segment where a loop is necessary.
    JMP _DONOTHING

_RET: ; Useful exit point for conditional returns.
    RET

; SECTION .END

TIMES 512-($-$$) db 0

STACKINIT:
    TIMES 1024 db 0
STACK: