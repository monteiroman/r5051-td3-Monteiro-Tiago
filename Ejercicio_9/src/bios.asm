;8. INTERRUPCIONES DE HARDWARE
;
;Utilizando lo realizado anteriormente, implementar las siguientes modificaciones:
;
;a) La rutina de adquisición de teclas debe realizarse en el controlador de
;   teclado (IRQ1). Se debe tener en cuenta que por cada presión de una tecla se
;   producen dos interrupciones, una por el make code y otra por el break code.
;
;b) Los dígitos correspondientes al alfabeto decimal conformarán un número de
;   64bits, es decir si se presionan las teclas 12345678, se debe almacenar en
;   la tabla de dígitos como una entrada que contiene al número 0000000012345678h.
;   Cada nuevo número se insertará en la tabla cuando se presione ENTER. Por
;   razones de simplicidad el buffer circular de teclado dispondrá de una longitud
;   de 9 bytes. En la tabla se ingresarán los últimos 16 dígitos hexadecimales
;   presionados al pulsar ENTER (123JH01AB4567CDEF89012LMNENTER equivale a
;   0000123456789012). Si al presionar ENTER se han ingresado menos de 8 Bytes,
;   se completarán con ceros en las posiciones MSB (1E.ENTER equivale
;   0000000000000001h).
;
;c) Escribir el controlador del temporizador (IRQ0 [10]) de modo que interrumpa
;   cada 100ms. Verifique el correcto funcionamiento almacenando en alguna
;   dirección de Datos el número de veces que se produce la interrupción. Tenga
;   en cuenta que la implementación del timer tick en Bochs no garantiza ejecución
;   del tipo tiempo real, es decir observará una falta de correspondencia temporal
;   entre la unidad de tiempo calculada y la que Bochs ejecuta en la práctica.
;
;El mapa de memoria debe ser el siguiente:
;
;               Sección                 |       Dirección inicial
;   ____________________________________|_________________________
;                ISR                    |          00000000h
;          Tablas de sistema            |          00100000h
;               Núcleo                  |          00200000h
;           Tabla de dígitos            |          00210000h
;               Datos                   |          00202000h
;               Pila                    |          1FF08000h
;    Secuencia inicialización ROM       |          FFFF0000h
;           Vector de reset             |          FFFFFFF0h
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Ejecucion:    make
; Limpeza:      make clean
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define BKPT    xchg    bx,bx

;______________________________________________________________________________;
;                           Modo protegido en 32 bits                          ;
;______________________________________________________________________________;

GLOBAL Inicio_32bits

;________________________________________
; Traigo las variables externas
;________________________________________

;Desde copia.asm.
EXTERN Funcion_copia

;Desde keyboard.asm.
EXTERN keyboard_fill_lookup_table
EXTERN keyboard_routine

;Desde init.asm.
EXTERN GDT_ROM
EXTERN DS_SEL_ROM
EXTERN CS_SEL_ROM
EXTERN tam_GDT_ROM
EXTERN GDT
EXTERN DS_SEL
EXTERN CS_SEL
EXTERN imagen_gdtr
EXTERN imagen_idtr
EXTERN init_IDT

;Desde el linkerscript.
EXTERN __STACK_START
EXTERN __STACK_END
EXTERN __KERNEL_DEST
EXTERN __KERNEL_ORIG
EXTERN __KERNEL_LENGTH
EXTERN __ROUTINES_DEST
EXTERN __ROUTINES_ORIG
EXTERN __ROUTINES_LENGTH
EXTERN __TABLES_DEST
EXTERN __TABLES_ORIG
EXTERN __TABLES_LENGTH
EXTERN __SYS_TABLES_DEST
EXTERN __SYS_TABLES_ORIG
EXTERN __SYS_TABLES_LENGTH

;Desde pic_init.asm.
EXTERN pic_init

USE32                   ;El codigo que continúa va en segmento de código
                                    ; de 32 BITS.

;________________________________________
; Inicialización en 32 bits
;________________________________________
section .init32
Inicio_32bits:

        mov     ax, DS_SEL_ROM  ;Cargo DS con el selector que apunta al
        mov     ds, ax              ;descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES.

        mov     ss, ax              ;Inicio el selector de pila.
        mov     esp, __STACK_END    ;Cargo el registro de pila y le doy
                                        ;direccion de inicio (recordar que se
                                        ;carga de arriba hacia abajo).

        ;BKPT

        ;Uso la pila para pasarle los valores a la funcion de copiado (mi nucleo).
        push    __KERNEL_ORIG     ;Posicion de origen .kernel (en ROM) que contiene a .copy.
        push    __KERNEL_DEST     ;Posicion destino 0x00200000 (en RAM).
        push    __KERNEL_LENGTH   ;Largo de la seccion .kernel que contiene a .copy.
        call    __KERNEL_ORIG
        pop     eax               ;Saco los valores de la pila.
        pop     eax
        pop     eax

        ;BKPT

        ;Copio la rutina de teclado a RAM.
        push    __ROUTINES_ORIG
        push    __ROUTINES_DEST
        push    __ROUTINES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;Copio la tabla de inspeccion de teclas a la memoria RAM.
        push    __TABLES_ORIG
        push    __TABLES_DEST
        push    __TABLES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;Lleno la tabla de inspeccion.
        call keyboard_fill_lookup_table

        ;BKPT

        ;Copio la GDT que va a correr desde memoria.
        push    GDT_ROM
        push    GDT
        push    tam_GDT_ROM
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;Cargo la nueva GDT que está en RAM.
        lgdt    [cs:imagen_gdtr]
        mov     ax, DS_SEL      ;Cargo DS con el selector que apunta al
        mov     ds, ax          ;   descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES
        mov     ss, ax          ;Inicio el selector de pila

        ;BKPT

        ;Cargo la imagen de idtr y los handlers.
        call init_IDT
        lidt [cs:imagen_idtr]

        ;Inicializo los pic's.
        call pic_init

        ;habilito las interrupciones
        sti

        jmp     CS_SEL:Main

;________________________________________
; Seccion Main
;________________________________________
section .main
Main:
        hlt
        jmp     Main
