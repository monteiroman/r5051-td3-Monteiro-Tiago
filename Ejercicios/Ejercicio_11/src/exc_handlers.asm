%define BKPT    xchg    bx,bx

GLOBAL handler#DE
GLOBAL handler#UD
GLOBAL handler#DF
GLOBAL handler#GP
GLOBAL handler#PF

;Desde init32.asm
EXTERN IDT
EXTERN CS_SEL
EXTERN CS_SEL_ROM

USE32

;______________________________________________________________________________;
;                       Manejadores de interrupciones                          ;
;______________________________________________________________________________;
section .exc_handlers

;Excepcion #DE (Divide error, [0x00])
handler#DE:
        pushad
        xor     edx, edx
        mov     dx, 0x00

        BKPT

        hlt
        popad
        iret

;Excepcion #UD (Invalid Upcode, [0x06])
handler#UD:
        pushad
        xor     edx, edx
        mov     dx, 0x06

        BKPT

        hlt
        popad
        iret

;Excepcion #DF (Double Fault, [0x08])
handler#DF:
        pushad
        xor     edx, edx
        mov     dx, 0x08

        BKPT

        hlt
        popad
        iret

;Excepcion #GP (General Protection, [0x0D])
handler#GP:
        pushad
        xor     edx, edx
        mov     dx, 0x0D

        BKPT

        hlt
        popad
        iret

;Excepcion #GP (General Protection, [0x0D])
handler#PF:
        pushad
        xor     edx, edx
        mov     dx, 0x0E

        BKPT

        hlt
        popad
        iret
