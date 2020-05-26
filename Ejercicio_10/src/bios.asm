;10. PAGINACIÓN BÁSICA
;Tomando como base al ejercicio anterior implementar un sistema de paginación
;[11] en modo identity mapping y adecuarlo a los siguientes lineamientos:
;
;a) Estructurar el programa de forma tal que disponga de las siguientes
;   secciones (la denominación se realiza acorde al estándar ELF) con sus
;   respectivas propiedades:
;
;   I. Sección de código (TEXT): no debe contener ningún tipo de dato/variable.
;
;   II. Sección de datos inicializados (DATA): debe subdividirse en una
;       subsección de solo lectura y otra de lectura/escritura.
;
;   III. Sección de datos no inicializados (BSS):
;
;b) Implementar un controlador básico de #PF que indique el motivo de la excepción.
;
;c) El tamaño del binario compactado no debe superar 64kB.
;
;d) El mapa de memoria luego de la expansión del binario debe cumplir con el
;   siguiente esquema:
;
;
;               Sección                 |       Dirección inicial
;   ____________________________________|_________________________
;                ISR                    |          00000000h
;               Video                   |          000B8000h
;          Tablas de sistema            |          00100000h
;        Tablas de paginación           |          00110000h
;               Núcleo                  |          00200000h
;            Tabla de dígitos           |          00210000h
;               Datos                   |          00202000h
;            TEXT Tarea 1               |          00300000h
;            BSS Tarea 1                |          00301000h
;            DATA Tarea 1               |          00302000h
;            Pila Nucleo                |          1FF08000h
;            Pila Tarea 1               |          1FFFF000h
;    Secuencia inicialización ROM       |          FFFF0000h
;           Vector de reset             |          FFFFFFF0h
;
; Utilizar alguna herramienta interpretación de ficheros binario para analizar
; los datos de posicionamiento en memoria.
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
EXTERN __TASK1_TXT_DEST
EXTERN __TASK1_TXT_ORIG
EXTERN __TASK1_TXT_LENGTH

;Desde pic_init.asm.
EXTERN pic_init

;Desde task1.asm
EXTERN sum_routine

; Desde screen.asm
EXTERN refresh_screen

; Desde paging.asm
EXTERN paging_init
EXTERN directorio;page_directory

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
        push    __TASK1_TXT_ORIG
        push    __TASK1_TXT_DEST
        push    __TASK1_TXT_LENGTH
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
        call    refresh_screen
        call    sum_routine
        jmp     Main
