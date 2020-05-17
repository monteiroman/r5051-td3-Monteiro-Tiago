;9. RUTINA TEMPORIZADA Y CONTROLADOR DE VIDEO
;
;Modificar el programa desarrollado hasta el momento considerando las siguientes
;consignas:
;
;a) Implementar una rutina que sume todos los números almacenados en la tabla de
;   dígitos, presente el resultado parcial en pantalla y el cómputo final sea
;   almacenado en alguna variable situada en Datos. La rutina debe cumplir los
;   siguientes requerimientos:
;
;           a. Ejecutarse cada 500ms.
;           b. No implementarse dentro de la IRQ0.
;           c. Situarse en la zona de Tarea 1.
;           d. Mientras no se ejecute establecer al procesador en estado halted.
;
;b) Adecuar el código y el linker script para satisfacer el siguiente mapa de
;   memoria.
;
;               Sección                 |       Dirección inicial
;   ____________________________________|_________________________
;                ISR                    |          00000000h
;          Tablas de sistema            |          00100000h
;               Núcleo                  |          00200000h
;           Tabla de dígitos            |          00210000h
;               Datos                   |          00202000h
;              Tarea 1                  |          00300000h
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
EXTERN __TASKS_DEST
EXTERN __TASKS_ORIG
EXTERN __TASKS_LENGTH

;Desde pic_init.asm.
EXTERN pic_init

;Desde task1.asm
EXTERN sum_routine

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

        ;Copio las rutinas y tablas asociadas a RAM.
        push    __ROUTINES_ORIG
        push    __ROUTINES_DEST
        push    __ROUTINES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;Lleno la tabla de inspeccion del teclado.
        call keyboard_fill_lookup_table

        ;BKPT

        ;Copio las tareas a RAM.
        push    __TASKS_ORIG
        push    __TASKS_DEST
        push    __TASKS_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

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
        ;BKPT
        call    sum_routine
        jmp     Main
