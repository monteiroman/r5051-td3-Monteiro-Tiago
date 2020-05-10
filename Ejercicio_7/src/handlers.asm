%define BKPT    xchg    bx,bx

GLOBAL IDT_handler_loader
GLOBAL IDT_handler_cleaner
GLOBAL handler#DE
GLOBAL handler#UD
GLOBAL handler#DF
GLOBAL handler#GP

;Desde init32.asm
EXTERN IDT
EXTERN CS_SEL
EXTERN CS_SEL_ROM

USE32

;______________________________________________________________________________;
;              Loader de descriptores de interrupciones                        ;
;______________________________________________________________________________;

;   Descriptor de IDT
;    _________________________________________
;   |   +7: Offset 31-24                      |
;   |_________________________________________|
;   |   +6: Offset 31-24                      |
;   |_________________________________________|
;   |   +5: Derechos de acceso                |
;   |        ________________________________ |
;   |       | 7 | 6   5 | 4 | 3   2   1   0 | |
;   |       | P |  DPL  | 0 | D   1   1   0 | |
;   |                       \____ Type ____/  |
;   |_________________________________________|
;   |   +4: CERO                              |
;   |_________________________________________|
;   |   +3: Selector 15-8                     |
;   |_________________________________________|
;   |   +2: Selector 7-0                      |
;   |_________________________________________|
;   |   +1: Offset 15-8                       |
;   |_________________________________________|
;   |   +0: Offset 7-0                        |
;   |_________________________________________|
;
;   P: Segment Present Flag
;   DPL: Descriptor Privilege Level
;   D: Size of gate
;   Type: E (1110)
;
section .init32

IDT_handler_loader:
        mov     esi, IDT
        mov     ebp, esp            ;No uso el puntero de pila directamente
        mov     ecx, [ebp+4]        ;Numero de Excepcion
        mov     edi, [ebp+8]        ;Dirección del Handler de la interrupcion

    ;Multiplico por 8. Me da la cantidad de veces que me tengo que mover desde
    ;el inicio de la IDT segun la interrupcion que tenga que llenar.
        shl     ecx,3

    ;+0:   Lo lleno en el proximo Paso
    ;+1:   Lleno el byte 1 y 0 con la parte baja de edi (16 primeros bits)
        mov     [esi+ecx],di        ;ebp+ecx me dan el lugar donde empieza descriptor

    ;+2;   Lo lleno en el siguiente Paso
    ;+3:   Pongo el selector de codigo.
        mov     ax, CS_SEL_ROM
        mov     [esi+ecx+2], ax     ;Sumo 2 para pararme en el byte 2 (estoy llenando ambos bytes).

    ;+4:    CERO
        mov     al, 0x00
        mov     [esi+ecx+4], al

    ;+5:    Derechos de acceso
        mov     al, 0x8E            ; 0x8E = 10001110
        mov     [esi+ecx+5], al     ;       Presente | permisos elevados | Tipo

    ;+6:    Lo lleno en el siguiente Paso
    ;+7:    Parte alta del offset (o sea de edi)
        rol     edi,16              ;Obtengo la parte alta en la parte baja
        mov     [esi+ecx+6], di

        ret

IDT_handler_cleaner:
        mov     esi, IDT
        mov     ebp, esp            ;No uso el puntero de pila directamente
        mov     ecx, [ebp+4]        ;Numero de Excepcion
        ;BKPT
        shl     ecx,3
        mov dword   [esi+ecx],0x0
        mov dword   [esi+ecx+4],0x0
        ;BKPT
        ret

;______________________________________________________________________________;
;                       Manejadores de interrupciones                          ;
;______________________________________________________________________________;
section .handlers

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
