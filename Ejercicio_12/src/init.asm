;______________________________________________________________________________;
;                                   Reset                                      ;
;______________________________________________________________________________;

section .reset
bits 16                         ;El código a continuación va en
                                    ;segmento de código de 16 bits

inicio_reset:                   ;Dirección de arranque del procesador.
       jmp      Inicio_16bits   ;Saltar al principio de la ROM.

times 0x10 - ($-inicio_reset) db 0        ;Relleno.


;______________________________________________________________________________;
;                              Modo real                                       ;
;______________________________________________________________________________;
GLOBAL GDT_ROM
GLOBAL DS_SEL_ROM
GLOBAL CS_SEL_ROM
GLOBAL tam_GDT_ROM

GLOBAL GDT
GLOBAL CS_SEL
GLOBAL DS_SEL
GLOBAL imagen_gdtr

GLOBAL IDT
GLOBAL imagen_idtr
GLOBAL init_IDT

GLOBAL IDT_handler_loader
GLOBAL IDT_handler_cleaner

;Desde bios.asm
EXTERN Inicio_32bits

;Desde exc_handlers.asm
EXTERN handler#DE
EXTERN handler#UD
EXTERN handler#DF
EXTERN handler#GP
EXTERN handler#PF

;Desde irq_handlers.asm
EXTERN irq#01_keyboard_handler
EXTERN irq#00_timer_handler


USE16                           ;El codigo que continúa va en segmento de código
                                    ; de 16 BITS
section .ROM_init
;________________________________________
; GDT de Rom
;________________________________________
        align 8                 ;Optimización para leer la GDT más rápido

GDT_ROM:
        dq 0                    ;Descriptor nulo. Simepre tiene que estar.

CS_SEL_ROM  equ $-GDT_ROM       ;Defino el selector de Código
                                ; Base = 00000000, límite = FFFFFFFF.
                                ; Granularidad = 1, límite = FFFFF.
        dw 0xffff               ;Límite 15-0
        dw 0                    ;Base 15-0
        db 0                    ;Base 23-16
        db 10011010b            ;Derechos de acceso.
                                    ;Bit 7 = 1 (Presente)
                                    ;Bits 6-5 = 0 (DPL)
                                    ;Bit 4 = 1 (Todavia no vimos por qué)
                                    ;Bit 3 = 1 (Código)
                                    ;Bit 2 = 0 (no conforming)
                                    ;Bit 1 = 1 (lectura)
                                    ;Bit 0 = 0 (Accedido).
        db 0xcf                 ;G = 1, D = 1, límite 19-16
        db 0                    ;Base 31-24

DS_SEL_ROM  equ $-GDT_ROM       ;Defino el selector de Datos flat.
                                ; Base 000000000, límite FFFFFFFF,
                                ; Granularidad = 1, límite = FFFFF.
        dw 0xffff               ;Límite 15-0
        dw 0                    ;Base 15-0
        db 0                    ;Base 23-16
        db 10010010b            ;Derechos de acceso.
                                    ;Bit 7 = 1 (Presente)
                                    ;Bits 6-5 = 0 (DPL)
                                    ;Bit 4 = 1 (Todavia no vimos por qué)
                                    ;Bit 3 = 0 (Datos)
                                    ;Bit 2 = 0 (dirección de expansión normal)
                                    ;Bit 1 = 1 (R/W)
                                    ;Bit 0 = 0 (Accedido)
        db 0xcf                 ;G = 1, D = 1, límite 19-16
        db 0                    ;Base 31-24

tam_GDT_ROM equ $-GDT_ROM       ;Tamaño de la GDT.

imagen_gdtr_ROM:
        dw tam_GDT_ROM - 1      ;Limite GDT (16 bits).
        dd GDT_ROM              ;Base GDT (32 bits).

;________________________________________
; Inicializacion de Modo protegido
;________________________________________
Inicio_16bits:

        cli                     ;Desabilitar interrupcionees.
        %include "src/init_pci.inc"     ;Inicialización de bus PCI y video
        o32 lgdt    [cs:imagen_gdtr_ROM]    ;Cargo registro GDTR.
                                            ;El prefijo 0x66 que agrega el o32
                                            ;permite usar los 4 bytes de la
                                            ;base. Sin o32 se usan tres.
        mov     eax, cr0        ;Paso a modo protegido.
        or      eax, 1          ;Prendo el bit 1
        mov     cr0, eax        ;Activo el modo protegido

        jmp dword CS_SEL_ROM:(Inicio_32bits)    ;Cambio el CS al selector
                                                ;de modo protegido de 32 bits.


;______________________________________________________________________________;
;                         Tablas del sistema                                   ;
;______________________________________________________________________________;
; Esta es la seccion en donde van a estar las tablas de GDT e IDT una vez que  ;
; mi nucleo las pase a RAM. Por ende, como van a trabajar en 32bits tengo que  ;
; poner USE32.                                                                 ;

USE32

section .system_tables nobits
;________________________________________
; GDT de Ram
;________________________________________
GDT:
        resb 8                      ;Descriptor nulo.
        CS_SEL equ $-GDT
        resb 8                      ;Selector de datos nulo. Se carga en tiempo de ejecución.
        DS_SEL equ $-GDT
        resb 8                      ;Selector de codigo nulo. Se carga en tiempo de ejecución.

        tam_GDT equ $-GDT           ;Tamaño de la GDT.

;________________________________________
; GDT de Ram
;________________________________________
IDT:
        resb 8*255                  ;Reservo 255 entradas de 8 bytes

        tam_IDT equ $-IDT


;______________________________________________________________________________;
;                Inicializacion de las Tablas del sistema                      ;
;______________________________________________________________________________;
section .init32
;________________________________________
; Imagen de GDTR de Ram
;________________________________________
imagen_gdtr:
        dw tam_GDT - 1      ;Limite GDT (16 bits).
        dd GDT              ;Base GDT (32 bits).

;________________________________________
; Imagen IDTR
;________________________________________
imagen_idtr:
        dw tam_IDT - 1      ;Limite IDT
        dd IDT              ;Base IDT

;________________________________________
; Inicializacion de interrupciones
;________________________________________
init_IDT:
    ;Excepcion #DE (Divide error, [0x00])
        push    handler#DE          ;Pongo el handler en pila
        push    0x00                ;Pongo el numero de interrupcion en pila
        call    IDT_handler_loader  ;Funcion que carga la interrupcion
        pop     eax
        pop     eax

    ;Excepcion #UD (Invalid Upcode, [0x06])
        push    handler#UD
        push    0x06
        call    IDT_handler_loader
        pop     eax
        pop     eax

    ;Excepcion #DF (Double Fault, [0x08])
        push    handler#DF
        push    0x08
        call    IDT_handler_loader
        pop     eax
        pop     eax

    ;Excepcion #GP (General Protection, [0x0D])
        push    handler#GP
        push    0x0D
        call    IDT_handler_loader
        pop     eax
        pop     eax

    ;Excepcion #PF (Page Fault, [0x0E])
        push    handler#PF
        push    0x0E
        call    IDT_handler_loader
        pop     eax
        pop     eax

    ;Interrupcion de teclado
        push    irq#01_keyboard_handler
        push    0x21
        call    IDT_handler_loader
        pop     eax
        pop     eax

    ;Interrupcion del timer
        push    irq#00_timer_handler
        push    0x20
        call    IDT_handler_loader
        pop     eax
        pop     eax

        ret


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
