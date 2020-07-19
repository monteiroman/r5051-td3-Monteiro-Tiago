;______________________________________________________________________________;
;                                   Reset                                      ;
;______________________________________________________________________________;

section .reset
bits 16                         ;El código a continuación va en
                                    ;segmento de código de 16 bits

inicio_reset:                   ;Dirección de arranque del procesador.
       jmp      Inicio_16bits   ;Saltar al principio de la ROM.

times 0x10 - ($ -inicio_reset) db 0        ;Relleno.


;______________________________________________________________________________;
;                              Modo real                                       ;
;______________________________________________________________________________;
EXTERN Inicio_32bits
GLOBAL DS_SEL
GLOBAL CS_SEL

USE16                           ;El codigo que continúa va en segmento de código
                                    ; de 16 BITS
section .init
;________________________________________
; GDT
;________________________________________
        align 8                 ;Optimización para leer la GDT más rápido

GDT:
        dq 0                    ;Descriptor nulo. Simepre tiene que estar.

CS_SEL  equ $-GDT               ;Defino el selector de Código
                                ; Base = 00000000, límite = FFFFFFFF.
                                ; Granularidad = 1, límite = FFFFF.
        dw 0xffff               ;Límite 15-0
        dw 0                    ;Base 15-0
        db 0                    ;Base 23-16
        db 10011010b            ;Derechos de acceso.
                                ;Bit 7 = 1 (Presente), Bits 6-5 = 0 (DPL),
                                ;Bit 4 = 1 (Todavia no vimos por qué),
                                ;Bit 3 = 1 (Código), Bit 2 = 0 (no conforming),
                                ;Bit 1 = 1 (lectura), Bit 0 = 0 (Accedido).
        db 0xcf                 ;G = 1, D = 1, límite 19-16
        db 0                    ;Base 31-24

DS_SEL  equ $-GDT               ;Defino el selector de Datos flat.
                                ; Base 000000000, límite FFFFFFFF,
                                ; Granularidad = 1, límite = FFFFF.
        dw 0xffff               ;Límite 15-0
        dw 0                    ;Base 15-0
        db 0                    ;Base 23-16
        db 10010010b            ;Derechos de acceso.
                                ;Bit 7 = 1 (Presente), Bits 6-5 = 0 (DPL),
                                ;Bit 4 = 1 (Todavia no vimos por qué),
                                ;Bit 3 = 0 (Datos), Bit 2 = 0 (dirección de
                                ;expansión) normal), Bit 1 = 1 (R/W),
                                ;Bit 0 = 0 (Accedido).
        db 0xcf                 ;G = 1, D = 1, límite 19-16
        db 0                    ;Base 31-24

tam_GDT equ $-GDT               ;Tamaño de la GDT.

imagen_gdtr:
        dw tam_GDT - 1          ;Limite GDT (16 bits).
        dd GDT                  ;Base GDT (32 bits).

;________________________________________
; Inicializacion de Modo protegido
;________________________________________
Inicio_16bits:

        cli                     ;Desabilitar interrupcionees.
        o32 lgdt    [cs:imagen_gdtr]    ;Cargo registro GDTR.
                                            ;El prefijo 0x66 que agrega el o32
                                            ;permite usar los 4 bytes de la
                                            ;base. Sin o32 se usan tres.
        mov     eax, cr0        ;Paso a modo protegido.
        or      eax, 1          ;Prendo el bit 1
        mov     cr0, eax        ;Activo el modo protegido

        jmp dword CS_SEL:(Inicio_32bits)    ;Cambio el CS al selector
                                                ;de modo protegido de 32 bits.
