; Mucha mas info aca: https://wiki.osdev.org/Paging

%define BKPT    xchg    bx,bx

%define SUP_RW_PRES_TableAttrib   0x03
%define SUP_RW_PRES_PageAttrib    0x03
%define SUP_R_PRES_PageAttrib     0x03

GLOBAL paging_init
GLOBAL page_directory

; Desde biosLS.lds
EXTERN __INIT_DEST
EXTERN __INIT_LENGTH
EXTERN __ROUTINES_DEST
EXTERN __ROUTINES_LENGTH
EXTERN __VIDEO_BUFFER_ORIG
EXTERN __VIDEO_BUFFER_SIZE
EXTERN __SYS_TABLES_DEST
EXTERN __SYS_TABLES_LENGTH
EXTERN __PAGING_TABLES_DEST
EXTERN __PAGING_TABLES_LENGTH
EXTERN __KERNEL_DEST
EXTERN __KERNEL_LENGTH
EXTERN __DATA_DEST
EXTERN __DATA_LENGTH
EXTERN __SAVED_DIGITS_TABLE_DEST
EXTERN __SAVED_DIGITS_TABLE_LENGTH
EXTERN __TASK1_TXT_DEST
EXTERN __TASK1_TXT_LENGTH
EXTERN __TASK1_BSS_DEST
EXTERN __TASK1_BSS_LENGTH
EXTERN __TASK1_DATA_R_DEST
EXTERN __TASK1_DATA_R_LENGTH
EXTERN __TASKS_DATA_RW_DEST
EXTERN __TASKS_DATA_RW_LENGTH
EXTERN __STACK_START
EXTERN __STACK_SIZE
EXTERN __TASK1_STACK_START
EXTERN __TASK1_STACK_SIZE

;________________________________________
;   Linear Address
;________________________________________
;
;    31______________________22__21_________________12__11______________0
;   |                          |                      |                 |
;   |   Page Directory Index   |   Page Table Index   |   Page Offset   |
;   |__________________________|______________________|_________________|
;           (10 bits)                 (10 bits)            (12 bits)
;
;
;________________________________________
;   Page Directory Entry
;________________________________________
;
;    31______________________11_10____9__8___7___6___5___4___3___2___1___0__
;   |                          |       |   |   |   |   |   |   |   |   |   |
;   |  Page_Table_Base_Address | Avail | G | S | 0 | A | D | W | U | R | P |
;   |__________________________|_______|___|___|___|___|___|___|___|___|___|
;
;           G = Ignored
;           S = Page size (0 for 4kb)
;           A = Accesed
;           D = Cache disabled
;           W = Write-Through
;           U = User/Supervisor
;           R = Read/Write
;           P = Present
;
;
;________________________________________
;   Page Table Entry
;________________________________________
;
;    31______________________11_10____9__8___7___6___5___4___3___2___1___0__
;   |                          |       |   |   |   |   |   |   |   |   |   |
;   |   Physical_Page_Address  | Avail | G | 0 | D | A | C | W | U | R | P |
;   |__________________________|_______|___|___|___|___|___|___|___|___|___|
;
;           G = Global
;           D = Dirty
;           A = Accesed
;           C = Cache disabled
;           W = Write-Through
;           U = User/Supervisor
;           R = Read/Write
;           P = Present
;
;
;   ________________________________________________________________________________________
;  |                          |                   |                      |                 |
;  |                          | Dirección inicial | Indice en Directorio | Indice en Tabla |
;  |         Sección          |                   |     de Paginas       |    de Paginas   |
;  |                          |                   |  (Tabla de Pagina)   |     (Pagina)    |
;  |__________________________|___________________|______________________|_________________|
;  |   ISR                    |    0x00000000     |        0x000         |      0x000      |
;  |   Video                  |    0x000B8000     |        0x000         |      0x0B8      |
;  |   Tablas de sistema      |    0x00100000     |        0x000         |      0x100      |
;  |   Tablas de paginación   |    0x00110000     |        0x000         |      0x110      |
;  |   Núcleo                 |    0x00200000     |        0x000         |      0x200      |
;  |   Datos                  |    0x00202000     |        0x000         |      0x202      |
;  |   Tabla de dígitos       |    0x00210000     |        0x000         |      0x210      |
;  |   TEXT Tarea 1           |    0x00300000     |        0x000         |      0x300      |
;  |   BSS Tarea 1            |    0x00301000     |        0x000         |      0x301      |
;  |   DATA Tarea 1           |    0x00302000     |        0x000         |      0x302      |
;  |   Pila Nucleo            |    0x1FF08000     |        0x07F         |      0x308      |
;  |   Pila Tarea 1           |    0x1FFFF000     |        0x07F         |      0x3FF      |
;  |   Inicialización ROM     |    0xFFFF0000     |        0x3FF         |      0x3F0      |
;  |   Vector de reset        |    0xFFFFFFF0     |        0x3FF         |      0x3FF      |
;
;   Necesito un Directorio de Paginas y 4 Tablas de Paginas (La pila de la tarea 1 empieza
;   en una tabla y termina en otra).
;
USE32
;______________________________________________________________________________;
;                           Tablas de Paginación                               ;
;______________________________________________________________________________;
section .paging_tables nobits
    page_directory:
        resd 1024           ; 1024 posiciones de 4 bytes cada una para el Directorio.
    page_tables:
        resd 1024*4         ; 1024 posiciones de 4 bytes cada una para
                            ;       cada Tabla de paginas (son 3).
    count_created_tables:
        resd 1              ; Cantidad de tablas creadas.


;______________________________________________________________________________;
;                           Paginación                                         ;
;______________________________________________________________________________;
section .init32

paging_init:

        push    __INIT_LENGTH               ; Largo de la sección.
        push    __INIT_DEST                 ; Direccion Física
        push    __INIT_DEST                 ; Dirección Lineal
        push    SUP_RW_PRES_TableAttrib     ; Atributos en directorio (de cada tabla)
        push    SUP_RW_PRES_PageAttrib      ; Atributos en tabla (de cada pagina)
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __ROUTINES_LENGTH
        push    __ROUTINES_DEST
        push    __ROUTINES_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __VIDEO_BUFFER_SIZE
        push    __VIDEO_BUFFER_ORIG
        push    __VIDEO_BUFFER_ORIG
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __SYS_TABLES_LENGTH
        push    __SYS_TABLES_DEST
        push    __SYS_TABLES_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __PAGING_TABLES_LENGTH
        push    __PAGING_TABLES_DEST
        push    __PAGING_TABLES_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __KERNEL_LENGTH
        push    __KERNEL_DEST
        push    __KERNEL_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __SAVED_DIGITS_TABLE_LENGTH
        push    __SAVED_DIGITS_TABLE_DEST
        push    __SAVED_DIGITS_TABLE_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __TASK1_TXT_LENGTH
        push    __TASK1_TXT_DEST
        push    __TASK1_TXT_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __TASK1_BSS_LENGTH
        push    __TASK1_BSS_DEST
        push    __TASK1_BSS_DEST
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __STACK_SIZE
        push    __STACK_START
        push    __STACK_START
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        push    __TASK1_STACK_SIZE
        push    __TASK1_STACK_START
        push    __TASK1_STACK_START
        push    SUP_RW_PRES_TableAttrib
        push    SUP_RW_PRES_PageAttrib
        call    paging
        pop     eax
        pop     eax
        pop     eax
        pop     eax
        pop     eax

        ret


;________________________________________
; Paginacion
;________________________________________
paging:
        mov     ebp, esp                    ; Traigo el puntero a pila
        mov     edi, [ebp + 0x0C]           ; Saco de la pila la direccion lineal
        mov     esi, [ebp + 0x0C]

    ; Obtengo el indice del Directorio de Pagina (me señala la tabla de Paginas).
        and     edi, 0xFFC00000             ; Obtengo los primeros 10 bits
        shr     edi, 0x16                   ; Muevo los bits hasta el principio del registro

    ; Obtengo el indice de la Tabla de Pagina (me señala la Pagina).
        and     esi, 0x003FF000             ; Obtengo los segundos 10 bits
        shr     esi, 0x0C                   ; Muevo los bits hasta el principio del registro

        overflowed_table:                   ; Si una tabla se sobrepasa, empiezo desde aca.

        mov     eax, [page_directory + edi * 4]     ; Traigo la entrada desde el directorio de pagina
        cmp     eax, 0x00                   ; Chequeo si ya existe la tabla
        je      create_table                ; Si no esta creada, salto a crearla.
        and     eax, 0xFFFFF000             ; Si existe, me quedo con la base de la entrada de directorio (dirección de la Tabla).
        jmp create_pages                    ; Si la tabla ya esta creada, salto
                                            ;   directamente a hacerle las paginas
    create_table:
        mov     ebx, [count_created_tables] ; Busco el contador de tablas creadas.
        inc     ebx                         ; Lo incremento.
        mov     [count_created_tables], ebx ; Guardo.

        shl     ebx, 0x0C                   ; Multiplico por 4096 (4 bytes * 1024 entradas) para ubicarme en la tabla.
        mov     ecx, page_tables            ; Comienzo de tablas de paginacion
        add     ecx, ebx                    ; Sumo el comienzo y el contador de tabla para conformar el indice.
        and     ecx, 0xFFFFF000             ; Borro los 12 bits menos significativos.
        mov     eax, ecx                    ; Guardo la dirección de la tabla para el proximo paso. (create_pages)
        mov     edx, [ebp + 0x08]           ; Saco los atributos de tabla de la pila.
        and     edx, 0x00000FFF             ; Limpio edx
        add     ecx, edx                    ; Le agrego los atributos de tabla.

        mov     [page_directory + edi * 4], ecx     ; Guardo el indice de tabla en el directorio.

    create_pages:
        mov     ebx, [ebp + 0x14]           ; Saco el largo de la sección de la pila.
        shr     ebx, 0x0C                   ; Divido por 4096. Me da la cantidad de paginas - 1.
        inc     ebx                         ; Cantidad de paginas que necesito para la sección.

        xor     edx, edx                    ; Limpio edx.
        mov     edx, esi
        shl     edx, 0x02                   ; Incremento el indice de Tabla (pagina nueva, 4 bytes).
        add     eax, edx                    ; "eax" es la dirección de la Tabla de Pagina, "edx" es el offset.

        mov     ecx, [ebp + 0x10]           ; Traigo la direccion fisica.
        xor     edx, edx                    ; Limpio edx.

        page_loop:                          ; Empiezo a crear las paginas.
            and     ecx, 0xFFFFF000         ; Limpio la dirección fisica
            add     ecx, [ebp + 0x04]       ; Saco de la pila y pego los atributos de Pagina.
            mov     [eax + edx * 4], ecx    ; Guardo la direccion de pagina en la entrada de Tabla.

            add     ecx, 0x1000             ; Incremento en 4k la dirección física. (nueva pagina).
            inc     edx                     ; Incremento el contador.

            inc     esi                     ; Incremento el indice de Tabla.
            cmp     esi, 0x400              ; Si llego al final de la tabla, tengo que hacer una nueva.
            jne     continue
                inc     edi                 ; Me voy a la siguiente entrada de directorio (pagina nueva)
                mov     esi, 0x00           ; Pongo el indice de tabla de pagina en cero (pagina cero)
                shl     edx, 0x0C           ; multiplico la cantidad de paginas creadas por 4k
                sub     [ebp + 0x14], edx   ; Corrijo la cantidad de paginas creadas
                add     [ebp + 0x10], edx   ; muevo la direccion fisica la cantidad de paginas que ya se crearon

                jmp     overflowed_table    ; Vuelvo para generar la nueva tabla.
            continue:
            cmp     edx, ebx                ; Comparo si terminé de crear la cantidad de paginas.
            jnz     page_loop               ; Sigo creando paginas.

        ret
