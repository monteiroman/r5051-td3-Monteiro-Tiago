;7.CONFIGURACIÓN DEL SISTEMA DE INTERRUPCIONES
;
;Tomando el ejercicio anterior, agregar una IDT [6][7] capaz de manejar todas
;las excepciones del procesador e interrupciones mapeadas por ambos PIC, es
;decir de la 0x00 hasta el tipo 0x2F y cumpla con los siguientes requerimientos.
;
;a) Configurar el PIC maestro y esclavo de manera que utilicen el rango de tipos
;   de interrupción 0x20-0x27 y 0x28-0x2F, respectivamente.
;
;b) Inicializar el registro de máscaras [8], de modo que estén deshabilitadas,
;   todas las interrupciones de hardware en ambos PIC’s.
;
;c) Implementar en todas las excepciones una rutina que permita identificar el
;   número de excepción generada y finalice deteniendo la ejecución de
;   instrucciones mediante la instrucción “hlt”. Se propone como método de
;   identificación almacenar en dx el número de excepción.
;
;d) Generar de manera apropiada [9] (no emulándolas por interrupciones de
;   software) para comprobar su funcionamiento las excepciones #DE, #UD, #DF y
;   #GP. Se recomienda asociar la generación de cada una de las excepciones
;   indicadas previamente a la pulsación de diferentes teclas. A tal fin se
;   propone la siguiente correspondencia: #DE=Y, #UD=U, #DF=I, #GP=O.
;
;e) La IDT se debe ubicar en Tablas de sistema
;
;El mapa de memoria debe ser el siguiente:
;
;               Sección                 |       Dirección inicial
;   ____________________________________|_________________________
;        Rutina de teclado e ISR        |          00000000h
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

;Desde copia
EXTERN Funcion_copia

;Desde keyboard
EXTERN keyboard_fill_lookup_table
EXTERN keyboard_routine

;Desde init
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

;Desde el linkerscript
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

;Desde pic_init.asm
EXTERN pic_init

USE32                   ;El codigo que continúa va en segmento de código
                                    ; de 32 BITS

;________________________________________
; Inicialización en 32 bits
;________________________________________
section .init32
Inicio_32bits:

        mov     ax, DS_SEL_ROM  ;Cargo DS con el selector que apunta al
        mov     ds, ax              ;descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES

        mov     ss, ax              ;Inicio el selector de pila
        mov     esp, __STACK_END    ;Cargo el registro de pila y le doy
                                        ;direccion de inicio (recordar que se
                                        ;carga de arriba hacia abajo)

        ;BKPT

        ;Uso la pila para pasarle los valores a la funcion de copiado (mi nucleo).
        push    __KERNEL_ORIG     ;Posicion de origen .kernel (en ROM) que contiene a .copy
        push    __KERNEL_DEST     ;Posicion destino 0x00200000 (en RAM)
        push    __KERNEL_LENGTH   ;Largo de la seccion .kernel que contiene a .copy
        call    __KERNEL_ORIG
        pop     eax               ;Saco los valores de la pila
        pop     eax
        pop     eax

        ;BKPT

        ;copio la rutina de teclado a RAM
        push    __ROUTINES_ORIG
        push    __ROUTINES_DEST
        push    __ROUTINES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;copio la tabla de inspeccion de teclas a la memoria RAM
        push    __TABLES_ORIG
        push    __TABLES_DEST
        push    __TABLES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;Lleno la tabla de inspeccion
        call keyboard_fill_lookup_table

        ;BKPT

        ;copio la GDT que va a correr desde memoria
        push    GDT_ROM
        push    GDT
        push    tam_GDT_ROM
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ;BKPT

        ;Cargo la nueva GDT que está en RAM
        lgdt    [cs:imagen_gdtr]
        mov     ax, DS_SEL      ;Cargo DS con el selector que apunta al
        mov     ds, ax          ;   descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES
        mov     ss, ax          ;Inicio el selector de pila

        ;BKPT

        ;Cargo la imagen de idtr y los handlers
        call init_IDT
        lidt [cs:imagen_idtr]

        call pic_init

        jmp     CS_SEL:Main

;________________________________________
; Seccion Main
;________________________________________
section .main
Main:
        ;BKPT

        call keyboard_routine

        BKPT

        hlt
