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

;Desde bios.asm
EXTERN Inicio_32bits

;Desde handlers.asm
EXTERN IDT_handler_loader
EXTERN handler#DE
EXTERN handler#UD
EXTERN handler#DF
EXTERN handler#GP


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

        ret
