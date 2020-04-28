;4. INICIALIZACIÓN BÁSICA UTILIZANDO EL LINKER
;
;Modificar el código del ejercicio anterior para satisfacer los siguientes
;requerimientos:
;
;b. El programa debe situarse al inicio de la ROM (0xFFFF0000)
;
;c. Copiarse y ejecutarse en las siguientes direcciones:
;        i.  0x00000000
;        ii. 0x00100000
;        iii.Dirección a elección. En esta última debe finalizar la ejecución.
;
;El mapa de memoria propuesto:
;                   Sección                     |    Dirección inicial
;       ________________________________________|___________________________
;               Binario copiado 1               |        00000000h
;               Binario copiado 2               |        00100000h
;               Binario copiado 3               |        00200000h
;               Pila                            |        1FF08000h
;               Secuencia inicialización ROM    |        FFFF0000h
;               Vector de reset                 |        FFFFFFF0h
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Compilacion:  nasm -f elf32 bios.asm -o bios.elf
; Linkeo:       ld -z max-page-size=0x1000 -Map memory.map --oformat=binary -m elf_i386 -T biosLS.lds bios.elf -o bios.bin
; Ejecucion:    bochs -qf bochs.cfg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define BKPT    xchg    bx,bx

;______________________________________________________________________________;
;                              Modo real                                       ;
;______________________________________________________________________________;

USE16                   ;El codigo que continúa va en segmento de código
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
        dd GDT     ;Base GDT (32 bits).

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
        or      eax, 1              ;Prendo el bit 1
        mov     cr0, eax            ;Activo el modo protegido

        jmp dword CS_SEL:(Inicio_32bits)     ;Cambio el CS al selector
                                                            ;de modo protegido.


;______________________________________________________________________________;
;                           Modo protegido en 32 bits                          ;
;______________________________________________________________________________;

;________________________________________
; Traigo las variables externas
;________________________________________
EXTERN __STACK_START
EXTERN __STACK_END
EXTERN __COPY_DEST1
EXTERN __COPY_DEST2
EXTERN __COPY_DEST3
EXTERN __COPY_ORIG
EXTERN __COPY_LENGTH


USE32                   ;El codigo que continúa va en segmento de código
                                    ; de 32 BITS

Inicio_32bits:

        mov     ax, DS_SEL      ;Cargo DS con el selector que apunta al
        mov     ds, ax              ;descriptor de segmento de datos flat.
        mov     es, ax

        mov     ss, ax           ;Inicio el selector de pila
        mov     esp, __STACK_END ;Cargo el registro de pila y le doy
                                    ;direccion de inicio (recordar que se carga
                                    ;de arriba hacia abajo)

        ;Uso la pila para pasarle los calores a la funcion de copiado
        push    __COPY_ORIG     ;Posicion de origen .functions (en ROM) que contiene a .copy
        push    __COPY_DEST1    ;Posicion destino 0x00000000 (en RAM)
        push    __COPY_LENGTH   ;Largo de la seccion .functions que contiene a .copy
        call    __COPY_ORIG
        pop     eax             ;Saco los valores de la pila
        pop     eax
        pop     eax

        BKPT

        jmp     CS_SEL:main

;________________________________________
; Seccion copia
;________________________________________

        ;Ahora estoy en RAM (0x00000000) entonces copio en las otras posiciones
main:
        push    Funcion_copia   ;Posicion origen (en RAM)
        push    __COPY_DEST2    ;Posicion destino 0x00100000 (en RAM)
        push    __COPY_LENGTH   ;Largo de la seccion .functions que contiene .copy
        call    Funcion_copia
        pop     eax             ;Saco los valores de la pila
        pop     eax
        pop     eax

        BKPT

        push    Funcion_copia   ;Posicion origen (en RAM)
        push    __COPY_DEST3    ;Posicion destino 0x00200000 (en RAM)
        push    __COPY_LENGTH   ;Largo de la seccion .functions que contiene .copy
        call    Funcion_copia
        pop     eax             ;Saco los valores de la pila
        pop     eax
        pop     eax

        hlt

;________________________________________
; Seccion copia
;________________________________________
section .copy

Funcion_copia:
        mov     ebp, esp        ;Copio la pila en otro registro para no meter la pata
        mov     ecx, [ebp+4]    ;Largo de lo que copio
        mov     edi, [ebp+8]    ;Destino de lo que copio
        mov     esi, [ebp+12]   ;Origen de lo que copio
        rep     cs movsb        ;Repiro la copa hasta copiar todos los bytes

        ret


;______________________________________________________________________________;
;                                   Reset                                      ;
;______________________________________________________________________________;

section .reset
bits 16                ;El código a continuación va en
                       ;segmento de código de 16 bits

inicio_reset:                     ;Dirección de arranque del procesador.
       jmp      Inicio_16bits     ;Saltar al principio de la ROM.

times 0x10 - ($ -inicio_reset) db 0        ;Segundo relleno.
