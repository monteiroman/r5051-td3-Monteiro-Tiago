;14. SIMD
;Modificar la Tarea 2 para que realice la suma aritmética saturada en tamaño 
;word y la Tarea 1 para que lo realice en tamaño quadruple word Implementar el 
;soporte necesario para el resguardo de los registros MMX/SSE mediante la
;excepción 7 (#NM), así como también realizar las modificaciones
;correspondientes en la función de cambio de contexto.
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

