%define BKPT    xchg    bx,bx
%define des_attrib_SU    0x8E    ; 10001110b Descriptor con DPL=0
%define des_attrib__U    0xEE    ; 11101110b Descriptor con DPL=3

;______________________________________________________________________________;
;                                   Reset                                      ;
;______________________________________________________________________________;

section .reset
bits 16                             ; El código a continuación va en
                                    ;   segmento de código de 16 bits.

inicio_reset:                       ; Dirección de arranque del procesador.
       jmp      Inicio_16bits       ; Saltar al principio de la ROM.

times 0x10 - ($-inicio_reset) db 0  ; Relleno.


;______________________________________________________________________________;
;                              Modo real                                       ;
;______________________________________________________________________________;

GLOBAL CS_SEL_KERNEL
GLOBAL init_GDT_RAM
GLOBAL init_IDT
GLOBAL IDT_handler_cleaner
GLOBAL TSS_SEL
GLOBAL CS_SEL_USER
GLOBAL DS_SEL_USER
GLOBAL CS_SEL_KERNEL
GLOBAL DS_SEL_KERNEL

;Desde bios.asm
EXTERN Inicio_32bits

;Desde exc_handlers.asm
EXTERN handler#DE
EXTERN handler#UD
EXTERN handler#DF
EXTERN handler#SS
EXTERN handler#GP
EXTERN handler#PF
EXTERN handler#NM
EXTERN handler#TS

;Desde irq_handlers.asm
EXTERN irq#01_keyboard_handler
EXTERN irq#00_timer_handler
EXTERN irq#80_syscall

;Desde copia.asm.
EXTERN Funcion_copia

;Desde el linkerscript.
EXTERN __STACK_END

; Desde scheduler.asm
EXTERN m_tss_length
EXTERN m_tss_kernel


USE16                               ; El codigo que continúa va en segmento de código
                                    ; de 16 BITS.
section .ROM_init
;________________________________________
; GDT de Rom
;________________________________________
        align 8                     ; Optimización para leer la GDT más rápido

GDT_ROM:
        dq 0                        ; Descriptor nulo. Simepre tiene que estar.

CS_SEL_KERNEL_ROM  equ $-GDT_ROM    ; Defino el selector de Código flat de KERNEL.
                                    ;   Base = 00000000, límite = FFFFFFFF.
                                    ;   Granularidad = 1, límite = FFFFF.
        dw 0xffff                   ; Límite 15-0
        dw 0                        ; Base 15-0
        db 0                        ; Base 23-16
        db 10011010b                ; Derechos de acceso.
                                    ;   Bit 7 = 1 (Presente)
                                    ;   Bits 6-5 = 0 (DPL)
                                    ;   Bit 4 = 1
                                    ;   Bit 3 = 1 (Código)
                                    ;   Bit 2 = 0 (no conforming)
                                    ;   Bit 1 = 1 (lectura)
                                    ;   Bit 0 = 0 (Accedido).
        db 0xcf                     ; G = 1, D = 1, límite 19-16
        db 0                        ; Base 31-24

DS_SEL_KERNEL_ROM  equ $-GDT_ROM    ; Defino el selector de Datos flat de KERNEL.
                                    ;   Base 000000000, límite FFFFFFFF,
                                    ;   Granularidad = 1, límite = FFFFF.
        dw 0xffff                   ; Límite 15-0
        dw 0                        ; Base 15-0
        db 0                        ; Base 23-16
        db 10010010b                ; Derechos de acceso.
                                    ;   Bit 7 = 1 (Presente)
                                    ;   Bits 6-5 = 0 (DPL)
                                    ;   Bit 4 = 1 (Todavia no vimos por qué)
                                    ;   Bit 3 = 0 (Datos)
                                    ;   Bit 2 = 0 (dirección de expansión normal)
                                    ;   Bit 1 = 1 (R/W)
                                    ;   Bit 0 = 0 (Accedido)
        db 0xcf                     ; G = 1, D = 1, límite 19-16
        db 0                        ; Base 31-24

CS_SEL_USER_ROM  equ $-GDT_ROM+0x03 ; Defino el selector de Código flat de USUARIO.
                                    ;   Base = 00000000, límite = FFFFFFFF.
                                    ;   Granularidad = 1, límite = FFFFF.
        dw 0xffff                   ; Límite 15-0
        dw 0                        ; Base 15-0
        db 0                        ; Base 23-16
        db 11111010b                ; Derechos de acceso.
                                    ;   Bit 7 = 1 (Presente)
                                    ;   Bits 6-5 = 11 (DPL)
                                    ;   Bit 4 = 1
                                    ;   Bit 3 = 1 (Código)
                                    ;   Bit 2 = 0 (no conforming)
                                    ;   Bit 1 = 1 (lectura)
                                    ;   Bit 0 = 0 (Accedido).
        db 0xcf                     ; G = 1, D = 1, límite 19-16
        db 0                        ; Base 31-24

DS_SEL_USER_ROM  equ $-GDT_ROM+0x03 ; Defino el selector de Datos flat de USUARIO.
                                    ;   Base 000000000, límite FFFFFFFF,
                                    ;   Granularidad = 1, límite = FFFFF.
        dw 0xffff                   ; Límite 15-0
        dw 0                        ; Base 15-0
        db 0                        ; Base 23-16
        db 11110010b                ; Derechos de acceso.
                                    ;   Bit 7 = 1 (Presente)
                                    ;   Bits 6-5 = 11 (DPL)
                                    ;   Bit 4 = 1 (Todavia no vimos por qué)
                                    ;   Bit 3 = 0 (Datos)
                                    ;   Bit 2 = 0 (dirección de expansión normal)
                                    ;   Bit 1 = 1 (R/W)
                                    ;   Bit 0 = 0 (Accedido)
        db 0xcf                     ; G = 1, D = 1, límite 19-16
        db 0                        ; Base 31-24


tam_GDT_ROM equ $-GDT_ROM           ; Tamaño de la GDT.

imagen_gdtr_ROM:
        dw tam_GDT_ROM - 1          ; Limite GDT (16 bits).
        dd GDT_ROM                  ; Base GDT (32 bits).


;________________________________________
; Inicializacion de Modo protegido
;________________________________________
Inicio_16bits:

        cli                                 ; Desabilitar interrupcionees.
        %include "src/init_pci.inc"         ; Inicialización de bus PCI y video
        o32 lgdt    [cs:imagen_gdtr_ROM]    ; Cargo registro GDTR.
                                            ; El prefijo 0x66 que agrega el o32
                                            ;   permite usar los 4 bytes de la
                                            ;   base. Sin o32 se usan tres.
        mov     eax, cr0                    ; Paso a modo protegido.
        or      eax, 1                      ; Prendo el bit 1
        mov     cr0, eax                    ; Activo el modo protegido

        mov     ax, DS_SEL_KERNEL_ROM       ; Cargo DS con el selector que apunta al
        mov     ds, ax                      ;   descriptor de segmento de datos flat.
        mov     es, ax                      ; Cargo ES.

        mov     ss, ax                      ; Inicio el selector de pila.
        mov     esp, __STACK_END            ; Cargo el registro de pila y le doy
                                            ;   direccion de inicio (recordar que se
                                            ;   carga de arriba hacia abajo).

        jmp dword CS_SEL_KERNEL_ROM:(Inicio_32bits)     ; Cambio el CS al selector 
                                                        ;   de modo protegido de 32 bits
                                                        ;   y salto a las inicializaciones
                                                        ;   de 32 bits (ver bios.asm).

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
        resb 8                      ; Descriptor nulo.
        CS_SEL_KERNEL equ $-GDT     ; Selector de codigo de kernel nulo. Se 
        resb 8                      ;   carga en tiempo de ejecución.
        DS_SEL_KERNEL equ $-GDT     ; Selector de datos de kernel nulo. Se carga
        resb 8                      ;   en tiempo de ejecución.
        CS_SEL_USER equ $-GDT+0x03  ; Selector de codigo de usuario nulo. Se
        resb 8                      ;   carga en tiempo de ejecución.
        DS_SEL_USER equ $-GDT+0x03  ; Selector de datos de usuario nulo. Se 
        resb 8                      ;   carga en tiempo de ejecución.
        TSS_SEL equ $-GDT           
        resb 8                      ; Selector de TSS.

        tam_GDT equ $-GDT           ; Tamaño de la GDT.


;________________________________________
; IDT de Ram
;________________________________________
IDT:
        resb 8*255                  ; Reservo 255 entradas de 8 bytes

        tam_IDT equ $-IDT


;______________________________________________________________________________;
;                Inicializacion de las Tablas del sistema                      ;
;______________________________________________________________________________;
section .init32
;________________________________________
; Imagen de GDTR de Ram
;________________________________________
imagen_gdtr:
        dw tam_GDT - 1              ; Limite GDT (16 bits).
        dd GDT                      ; Base GDT (32 bits).


;________________________________________
; Imagen IDTR
;________________________________________
imagen_idtr:
        dw tam_IDT - 1              ; Limite IDT
        dd IDT                      ; Base IDT


;________________________________________
; Inicializacion de GDT en RAM
;________________________________________
init_GDT_RAM:
    ; Copio la GDT que va a correr desde memoria.
        push    GDT_ROM             ; Posicion de origen (en ROM) que contiene a la GDT.
        push    GDT                 ; Posicion destino (en RAM).
        push    tam_GDT_ROM         ; Largo de la GDT de ROM, la de RAM es mas grande (tiene TSS).
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

    ; Cargo el selector de la TSS en la GDT.
        mov     ebp, GDT                            ; Comienzo de la GDT de RAM
        mov     eax, m_tss_kernel                   ; Direccion de la TSS que voy a cargar en GDT
        mov     ebx, m_tss_length                   ; Largo de la TSS.
        mov     ecx, ebx
        rol     ecx, 0x10                           ; Giro el largo
        and     cl, 0x0F                            ; Bits 19 a 16 del largo.
        or      cl, 0x40                            ; G=0, D=1 (de 32 bits).

        mov     [ebp + TSS_SEL], bx                 ; Bytes 0 a 1: bits 0-15 del limite.
        mov     [ebp + TSS_SEL + 0x02], ax          ; Bytes 2 a 3: bits 0-15 de la base.
        rol     eax, 0x10                           ; Giro la direccion de la TSS
        mov     [ebp + TSS_SEL + 0x04], al          ; Byte 4: bits 16-23 de la base.
        mov     [ebp + TSS_SEL + 0x05], dword 0x89  ; Byte 5: 100010B1 en binario. B lo escribe el micro  .
        mov     [ebp + TSS_SEL + 0x06], cl          ; Byte 6: G=0, D=1, 0, 0, bits 16-19 del limite. 
        mov     [ebp + TSS_SEL + 0x07], ah          ; Byte 7: bits 24-31 de la base.   

    ; Cargo la nueva GDT que está en RAM.
        lgdt    [cs:imagen_gdtr]

    ; Cargo los selectores.
        mov     ax, DS_SEL_KERNEL   ; Cargo DS con el selector que apunta al
        mov     ds, ax              ;   descriptor de segmento de datos flat.
        mov     es, ax              ; Cargo ES
        mov     ss, ax              ; Inicio el selector de pila

        ret


;________________________________________
; Inicializacion de IDT
;________________________________________
init_IDT:
    ; Excepcion #DE (Divide error, [0x00])
        push    des_attrib_SU       ; Pongo los atributos del descriptor.
        push    handler#DE          ; Pongo el handler en pila (ver exc_handlers.asm).
        push    0x00                ; Pongo el numero de interrupcion en pila
        call    IDT_handler_loader  ; Funcion que carga la interrupcion
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #UD (Invalid Upcode, [0x06])
        push    des_attrib_SU       
        push    handler#UD          ; Ver exc_handlers.asm.
        push    0x06
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #NM (Device not available, [0x07])
        push    des_attrib_SU       
        push    handler#NM          ; Ver exc_handlers.asm.
        push    0x07
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #DF (Double Fault, [0x08])
        push    des_attrib_SU       
        push    handler#DF          ; Ver exc_handlers.asm.
        push    0x08
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #TS (Invalid TSS, [0x0A])
        push    des_attrib_SU       
        push    handler#TS          ; Ver exc_handlers.asm.
        push    0x0A
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #SS (Stack Segment Fault, [0x0C])
        push    des_attrib_SU       
        push    handler#SS          ; Ver exc_handlers.asm.
        push    0x0C
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #GP (General Protection, [0x0D])
        push    des_attrib_SU       
        push    handler#GP          ; Ver exc_handlers.asm.
        push    0x0D
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Excepcion #PF (Page Fault, [0x0E])
        push    des_attrib_SU       
        push    handler#PF          ; Ver exc_handlers.asm.
        push    0x0E
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Interrupcion de teclado
        push    des_attrib_SU       
        push    irq#01_keyboard_handler     ; Ver irq_handlers.asm
        push    0x21
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Interrupcion del timer
        push    des_attrib_SU       
        push    irq#00_timer_handler        ; Ver irq_handlers.asm
        push    0x20
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Interrupcion de syscall.
        push    des_attrib__U
        push    irq#80_syscall              ; Ver irq_handlers.asm
        push    0x80
        call    IDT_handler_loader
        pop     eax
        pop     eax
        pop     eax

    ; Cargo la imagen de IDT 
        lidt    [cs:imagen_idtr]

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

IDT_handler_loader:
        mov     esi, IDT
        mov     ebp, esp            ; No uso el puntero de pila directamente
        mov     ecx, [ebp + 4]      ; Numero de Excepcion
        mov     edi, [ebp + 8]      ; Dirección del Handler de la interrupcion

    ;Multiplico por 8. Me da la cantidad de veces que me tengo que mover desde
    ;el inicio de la IDT segun la interrupcion que tenga que llenar.
        shl     ecx,3

    ;+0:   Lo lleno en el proximo Paso
    ;+1:   Lleno el byte 1 y 0 con la parte baja de edi (16 primeros bits)
        mov     [esi+ecx],di        ; ebp+ecx me dan el lugar donde empieza descriptor

    ;+2;   Lo lleno en el siguiente Paso
    ;+3:   Pongo el selector de codigo.
        mov     ax, CS_SEL_KERNEL
        mov     [esi+ecx+2], ax     ; Sumo 2 para pararme en el byte 2 (estoy llenando ambos bytes).

    ;+4:    CERO
        mov     al, 0x00
        mov     [esi+ecx+4], al

    ;+5:    Derechos de acceso
        mov     al, [ebp + 12]      ; Atributos.
        mov     [esi+ecx+5], al     ;       Presente | permisos elevados | Tipo

    ;+6:    Lo lleno en el siguiente Paso
    ;+7:    Parte alta del offset (o sea de edi)
        rol     edi,16              ; Obtengo la parte alta en la parte baja
        mov     [esi+ecx+6], di

        ret


IDT_handler_cleaner:
        mov     esi, IDT
        mov     ebp, esp            ; No uso el puntero de pila directamente
        mov     ecx, [ebp+4]        ; Numero de Excepcion

        shl     ecx,3
        mov dword   [esi+ecx],0x0
        mov dword   [esi+ecx+4],0x0

        ret
