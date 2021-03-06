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

;Desde init.asm.
EXTERN GDT
EXTERN CS_SEL_KERNEL
EXTERN init_IDT
EXTERN init_GDT_RAM

;Desde el linkerscript.
EXTERN __KERNEL_PHY
EXTERN __KERNEL_ORIG
EXTERN __KERNEL_LENGTH
EXTERN __ROUTINES_LIN
EXTERN __ROUTINES_ORIG
EXTERN __ROUTINES_LENGTH
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

; Desde paging.asm
EXTERN paging_init
EXTERN kernel_page_directory

; Desde scheduler.asm
EXTERN scheduler_init

USE32                   ;El codigo que continúa va en segmento de código
                                    ; de 32 BITS.
;________________________________________
; Inicialización en 32 bits
;________________________________________
section .init32
Inicio_32bits:
        ; Estas dos secciones las copio a RAM antes de paginar para poder 
        ; protegerlas por paginacion. De esta manera puedo poner que sus paginas
        ; sean de solo lectura.
        ; Uso la pila para pasarle los valores a la funcion de copiado (mi nucleo).
        push    __KERNEL_ORIG       ;Posicion de origen .kernel (en ROM) que contiene a .copy.
        push    __KERNEL_PHY        ;Posicion destino (en RAM).
        push    __KERNEL_LENGTH     ;Largo de la seccion .kernel que contiene a .copy.
        call    __KERNEL_ORIG
        pop     eax                 ;Saco los valores de la pila.
        pop     eax
        pop     eax

        ; Copio las rutinas y tablas asociadas a RAM.
        push    __ROUTINES_ORIG
        push    __ROUTINES_LIN      ; La misma que la fisica (identity maping). 
        push    __ROUTINES_LENGTH
        call    __KERNEL_ORIG
        pop     eax
        pop     eax
        pop     eax

        ; Paginación (ver paging.asm)
        call    paging_init
        mov     eax, kernel_page_directory
        mov     CR3, eax            ; Cargo CR3 con la direccion del directorio

        mov     eax, CR0            ; Activo la paginación poniendo en 1 el
        or      eax, 0x80000000     ;   bit 31 de CR0.
        mov     CR0, eax

        ; Lleno la tabla de inspeccion del teclado (ver keyboard.asm).
        call    keyboard_fill_lookup_table

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

        ; Cargo la GDT a RAM y configuro los registros de segmentos (ver init.asm)
        call    init_GDT_RAM

        ; Cargo la imagen de idtr y los handlers (ver init.asm).
        call    init_IDT

        ; Inicializo los pic's (ver pic_init.asm).
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

        jmp     CS_SEL_KERNEL:Main

;________________________________________
; Seccion Main
;________________________________________
section .main
Main:
        jmp     scheduler_init      ; Ver scheduler.asm

