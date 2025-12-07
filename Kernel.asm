BITS 16
ORG 0x0000

;DOCUMENTATION: This may be branched into a text file later.

    ;V0.0.4 | Input is now properly stored and limited, kernel text can no longer be deleted.
    ;V0.0.3 | Stack redefined for usage in later variants, input buffer defined.
    ;V0.0.2 | Implemented F10 as a special key, changing video mode and launching a demo. This will remain untouched until much later.
    ;V0.0.1b | Reformatted code for attachment to BOOTLOADER.ASM.
    ;V0.0.1 | Added support for Enter and Backspace keys.
    ;V0.0.0 | Added basic text functionality.

;FUNCTIONS AND THEIR PARAMETERS:
    ;_WRITESTR: [(BX, 'STRNAME')], Prints a specified string to the console. Push and pop BX before/after using this or you will regret it.
    ;_BOOTKEY: [nil], Not necessarily a function, but enters the graphical environment. There will be no way to return to the terminal.


; Magic Destroyer MAGIC_DESTROYER_VERSION
INBUFSIZE EQU 16

; SECTION .TERMINAL

_START:
    MOV AH, 0 ; set the video mode to
    MOV AL, 3 ; this one
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
    CMP AH, 0x1C ;Enter Scan Code
    JE _ENTERPRESSED
    CMP AH, 0x0E ;Backspace Scan Code
    JE _BACKSPACEPRESSED
    CMP AH, 0x44 ;F10 Scan Code
    JE _BOOTKEY
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
    MOV WORD [INPTR], 0
    MOV AH, 14
    MOV AL, 0x0D
    INT 0x10
    MOV AL, 0x0A
    INT 0x10
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
    MOV AH, 0X0 ; Video Mode
    MOV AL, 0X11 ; Monochrome VGA
    INT 0X10
    JMP _INITGRAPHICS        

; SECTION .TERMINAL_DATA


INTROMES   db 'BOOT SUCCESSFUL. TERMINAL.', 0
KERNPREFIX    db 'KERNEL*//>', 0
INBUF   TIMES (INBUFSIZE + 1) db 0
INPTR   dw 0   

; SECTION .GRAPHICS

_INITGRAPHICS:
    MOV AX, 0xA000 ; VRAM Location
    MOV ES, AX
    MOV AL, 0X00 ; Fill with this pattern
    JMP _LOOPIT



_LOOPIT:
    MOV DI, 0x0 ; Offset of VRAM (0)
    MOV CX, 0X9600 ; Repeat this many times
    CLD
    REP STOSB
    INC AL
    JMP _LOOPIT


; SECTION .GRAPHICS_DATA

; SECTION .AUXILARY

_DONOTHING: ; Use this as a placeholder for a segment where a loop is necessary.
    JMP _DONOTHING

_RET: ; Exit point for subroutines meant to be but not designed as functions.
    RET

; SECTION .END

TIMES 512-($-$$) db 0

STACKINIT:
    TIMES 1024 db 0
STACK:
