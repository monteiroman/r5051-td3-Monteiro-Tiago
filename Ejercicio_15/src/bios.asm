;15. NIVELES DE PRIVILEGIO
;En base a lo elaborado anteriormente implementar un sistema que permita manejar
;niveles de privilegio. A tal fin modificar/agregar los siguientes ítems:
;
;   a) La GDT debe contemplar los descriptores de nivel 3 (PL=11 usuario), tanto
;       para código como para datos.
;
;   b) Adecuar las diferentes entradas de la tabla de paginación según 
;       corresponda a usuario o supervisor, verificando además que los permisos 
;       de lectura y escritura sean consistentes con la sección asociada.
;
;   c) Las tareas 1 y 2 deben ejecutarse en nivel 3. Analizar si es necesario 
;       disponer de una pila por cada tarea y realizar las modificaciones 
;       pertinentes acorde a su respuesta.
;
;   d) Diseñar un mecanismo apropiado de acceso para las siguientes funciones de
;       sistema (system calls). Utilice el vector 80h para los servicios, o bien
;       un CALL FAR.
;           i.  void td3_halt(void);
;           ii. unsigned int td3_read(void *buffer, unsigned int num_bytes);
;           iii.unsigned int td3_print(void *buffer, unsigned int num_bytes);
;
;   e) Modificar el mapa de memoria al siguiente esquema:
;
;         Sección        | Dirección física inicial | Dirección lineal inicial
;   _____________________|__________________________|___________________________
;   ISR                  |         00000000h        |        00000000h
;   Video                |         000B8000h        |        00010000h
;   Tablas de sistema    |         00100000h        |        00100000h
;   Tablas de paginación |         00110000h        |        00110000h
;   Núcleo               |         00200000h        |        01200000h
;   Datos                |         00202000h        |        01202000h
;   Tabla de dígitos     |         00210000h        |        01210000h
;   TEXT Tarea 1         |         00300000h        |        01300000h
;   BSS Tarea 1          |         00301000h        |        01301000h
;   DATA Tarea 1         |         00302000h        |        01302000h
;   TEXT Tarea 2         |         00310000h        |        01310000h
;   BSS Tarea 2          |         00311000h        |        01311000h
;   DATA Tarea 2         |         00312000h        |        01312000h
;   TEXT Tarea 3         |         00320000h        |        01320000h
;   BSS Tarea 3          |         00321000h        |        01321000h
;   DATA Tarea 3         |         00322000h        |        01322000h
;   Pila Nucleo          |         1FF08000h        |        1FF08000h
;   Pila Núcleo Tarea 3  |         1FF05000h        |        00714000h
;   Pila Núcleo Tarea 2  |         1FF06000h        |        00714000h
;   Pila Núcleo Tarea 1  |         1FF07000h        |        00714000h
;   Pila Tarea 3         |         1FFFD000h        |        00713000h
;   Pila Tarea 2         |         1FFFE000h        |        00713000h
;   Pila Tarea 1         |         1FFFF000h        |        00713000h
;   Secuencia inic. ROM  |         FFFF0000h        |        FFFF0000h
;   Vector de reset      |         FFFFFFF0h        |        FFFFFFF0h
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
EXTERN __TASK3_TXT_LIN
EXTERN __TASK3_TXT_ORIG
EXTERN __TASK3_TXT_LENGTH

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

; Desde scheduler.asm
EXTERN scheduler_init

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

        ; Copio las rutinas y tablas asociadas a RAM.
        push    __ROUTINES_ORIG
        push    __ROUTINES_LIN
        push    __ROUTINES_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ; Lleno la tabla de inspeccion del teclado.
        call keyboard_fill_lookup_table

        ; Copio las tareas a RAM.

        push    __TASK1_TXT_ORIG
        push    __TASK1_TXT_LIN
        push    __TASK1_TXT_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        push    __TASK2_TXT_ORIG
        push    __TASK2_TXT_LIN
        push    __TASK2_TXT_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        push    __TASK3_TXT_ORIG
        push    __TASK3_TXT_LIN
        push    __TASK3_TXT_LENGTH
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ; Copio la GDT que va a correr desde memoria.
        push    GDT_ROM
        push    GDT
        push    tam_GDT_ROM
        call    Funcion_copia
        pop     eax
        pop     eax
        pop     eax

        ; Cargo la nueva GDT que está en RAM.
        lgdt    [cs:imagen_gdtr]
        mov     ax, DS_SEL      ;Cargo DS con el selector que apunta al
        mov     ds, ax          ;   descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES
        mov     ss, ax          ;Inicio el selector de pila

        ; Cargo la imagen de idtr y los handlers.
        call    init_IDT
        lidt    [cs:imagen_idtr]

        ; Inicializo los pic's.
        call    pic_init

        ; Inicializo SIMD
        ; https://wiki.osdev.org/CPU_Registers_x86#CR4
        ; https://wiki.osdev.org/CPU_Registers_x86#CR0
        mov     eax, cr0            
        and     eax, 0xFFFFFFFB     ; Pongo en 0 el bit 2 (Emulation).
        mov     cr0, eax            

        mov     eax, cr4            
        or      eax, 0x600          ; Pongo en 1 el bit 9 (osfxsr) y 10 (osxmmexcpt)
        mov     cr4, eax            

        ; Habilito las interrupciones
        sti

        jmp     CS_SEL:Main

;________________________________________
; Seccion Main
;________________________________________
section .main
Main:
        jmp     scheduler_init

