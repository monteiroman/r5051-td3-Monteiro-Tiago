;13. CONMUTACIÓN DE TAREAS
;Incorpore al programa desarrollado hasta el momento una capacidad mínima de
;administración de tareas. Para ello se requiere, agregar las siguientes 
;prestaciones:
;
;a) Implementar 3 tareas a saber:
;       i.Suma (2 tareas). Estas tareas se ejecutarán cada 100 y 200 ms. 
;         respectivamente.
;         En todos los casos utilizarán los mismos datos como sumandos 
;         (Tabla de dígitos), presentado el resultado en pantalla y al finalizar
;         debe establecer al procesador en estado halted. Deshabilitar (no 
;         borrar) el código de generación de PF.
;       ii.Idle (1 tarea). Su única función es establecer al procesador en 
;         estado halted y se debe ejecutar cuando ninguna otra tarea se 
;         encuentre en ejecución.
;
;b) Modificar el valor del temporizador 0 del PIT, para que genere una 
;   interrupción cada 10 mseg aproximadamente.
;
;c) Modificar el controlador de la interrupción 32 (IRQ0, timer tick), para que
;   actué como conmutador de tareas (scheduler). Diseñe dicho mecanismo para que
;   despache las tareas en forma secuencial. El mecanismo de conmutación de 
;   contextos deberá implementarlo finalmente de forma manual (transitoriamente 
;   puede analizar el mecanismo automático provisto por el procesador).
;
;d) Modificar el mapa de memoria al siguiente esquema
;
;
;
;        Sección        | Dirección física inicial | Dirección lineal inicial
;  _____________________|__________________________|___________________________
;  ISR                  |         00000000h        |        00000000h
;  Video                |         000B8000h        |        00010000h
;  Tablas de sistema    |         00100000h        |        00100000h
;  Tablas de paginación |         00110000h        |        00110000h
;  Núcleo               |         00200000h        |        01200000h
;  Datos                |         00202000h        |        01202000h
;  Tabla de dígitos     |         00210000h        |        01210000h
;  TEXT Tarea 1         |         00300000h        |        01300000h
;  BSS Tarea 1          |         00301000h        |        01301000h
;  DATA Tarea 1         |         00302000h        |        01302000h
;  TEXT Tarea 2         |         00310000h        |        01310000h
;  BSS Tarea 2          |         00311000h        |        01311000h
;  DATA Tarea 2         |         00312000h        |        01312000h
;  TEXT Tarea 3         |         00320000h        |        01320000h
;  BSS Tarea 3          |         00321000h        |        01321000h
;  DATA Tarea 3         |         00322000h        |        01322000h
;  Pila Nucleo          |         1FF08000h        |        1FF08000h
;  Pila Tarea 3         |         1FFFD000h        |        00713000h
;  Pila Tarea 2         |         1FFFE000h        |        00713000h
;  Pila Tarea 1         |         1FFFF000h        |        00713000h
;  Secuencia inic. ROM  |         FFFF0000h        |        FFFF0000h
;  Vector de reset      |         FFFFFFF0h        |        FFFFFFF0h
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
EXTERN __KERNEL_LIN
EXTERN __KERNEL_ORIG
EXTERN __KERNEL_LENGTH
EXTERN __ROUTINES_LIN
EXTERN __ROUTINES_ORIG
EXTERN __ROUTINES_LENGTH
EXTERN __TABLES_DEST
EXTERN __TABLES_ORIG
EXTERN __TABLES_LENGTH
EXTERN __SYS_TABLES_LIN
EXTERN __SYS_TABLES_ORIG
EXTERN __SYS_TABLES_LENGTH
EXTERN __TASK1_TXT_LIN
EXTERN __TASK1_TXT_ORIG
EXTERN __TASK1_TXT_LENGTH
EXTERN __TASK2_TXT_LIN
EXTERN __TASK2_TXT_ORIG
EXTERN __TASK2_TXT_LENGTH

;Desde pic_init.asm.
EXTERN pic_init

;Desde task1.asm
EXTERN sum_routine

;Desde task2.asm
EXTERN sum_routine_2

; Desde screen.asm
EXTERN refresh_screen

; Desde paging.asm
EXTERN paging_init
EXTERN kernel_page_directory
EXTERN task1_page_directory
EXTERN task2_page_directory
EXTERN task3_page_directory               

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
        ; Paginación
        call    paging_init
        mov     eax, kernel_page_directory
        mov     CR3, eax            ; Cargo CR3 con la direccion del directorio

        mov     eax, CR0            ; Activo la paginación poniendo en 1 el
        or      eax, 0x80000000     ;   bit 31 de CR0.
        mov     CR0, eax

        ; Uso la pila para pasarle los valores a la funcion de copiado (mi nucleo).
        push    __KERNEL_ORIG     ;Posicion de origen .kernel (en ROM) que contiene a .copy.
        push    __KERNEL_LIN      ;Posicion destino 0x00200000 (en RAM).
        push    __KERNEL_LENGTH   ;Largo de la seccion .kernel que contiene a .copy.
        call    __KERNEL_ORIG
        pop     eax               ;Saco los valores de la pila.
        pop     eax
        pop     eax

        ;BKPT

        ; Copio las rutinas y tablas asociadas a RAM.
        push    __ROUTINES_ORIG
        push    __ROUTINES_LIN
        push    __ROUTINES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ; Lleno la tabla de inspeccion del teclado.
        call keyboard_fill_lookup_table

        ;BKPT

        ; Copio las tareas a RAM.
        ;BKPT

        push    __TASK1_TXT_ORIG
        push    __TASK1_TXT_LIN
        push    __TASK1_TXT_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        push    __TASK2_TXT_ORIG
        push    __TASK2_TXT_LIN
        push    __TASK2_TXT_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ; Copio la GDT que va a correr desde memoria.
        push    GDT_ROM
        push    GDT
        push    tam_GDT_ROM
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ; Cargo la nueva GDT que está en RAM.
        lgdt    [cs:imagen_gdtr]
        mov     ax, DS_SEL      ;Cargo DS con el selector que apunta al
        mov     ds, ax          ;   descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES
        mov     ss, ax          ;Inicio el selector de pila

        ;BKPT

        ; Cargo la imagen de idtr y los handlers.
        call    init_IDT
        lidt    [cs:imagen_idtr]

        ; Inicializo los pic's.
        call    pic_init

        ; Habilito las interrupciones
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
        call    sum_routine_2
        ;BKPT
        jmp     Main
