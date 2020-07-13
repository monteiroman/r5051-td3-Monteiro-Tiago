%define BKPT    xchg    bx,bx

%define Master_PIC_Command  0x20

; Identificador de funcion.
%define td3_halt    0x11
%define td3_read    0x22
%define td3_print   0x33

; Identificador de Tarea.
%define     task1_id    0x01
%define     task2_id    0x02

; Ubicacion de los digitos en a pantalla.
%define     num_row_offset          0x0A
%define     num_column_offset       0x19
%define     num_row_offset_2        0x0B
%define     num_column_offset_2     0x19

; Ubicacion en el contexto.
%define m_at_syscall    0x68
%define m_task_end      0x6C

GLOBAL irq#01_keyboard_handler
GLOBAL irq#00_timer_handler
GLOBAL irq#80_syscall
GLOBAL m_scheduler_int_end

; Desde keyboard.asm
EXTERN keyboard_routine

; Desde timer.asm
EXTERN timer_routine

; Desde Scheduler
EXTERN m_scheduler

; Desde scheduler.asm
EXTERN current_task
EXTERN at_syscall_t1
EXTERN at_syscall_t2
EXTERN at_syscall_t3
EXTERN task1_end_flag
EXTERN task2_end_flag
EXTERN task3_end_flag


; Desde biosLS.lds
EXTERN __TASK1_DATA_RW_LIN
EXTERN __TASK1_DATA_RW_END
EXTERN __TASK2_DATA_RW_LIN
EXTERN __TASK2_DATA_RW_END

; Desde screen.asm
EXTERN print_result

; Desde keyboard.asm
EXTERN saved_digits_table
EXTERN saved_digits_table_index

USE32

;______________________________________________________________________________;
;                       Manejadores de interrupciones                          ;
;______________________________________________________________________________;
section .irq_handlers

irq#00_timer_handler:
        call    timer_routine
    
        jmp     m_scheduler         ; Voy al scheduler (ver scheduler.asm).
        m_scheduler_int_end:        ; Punto de retorno

        push    eax                 ; Pusheo a pila eax porq lo voy a usar para otra cosa.

        mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion.
        out     Master_PIC_Command, al

        pop     eax                 ; Popeo para mantener el eax del contexto.
        iret

irq#01_keyboard_handler:
        pushad
        call    keyboard_routine    ; Ver keyboard.asm.
        mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion
        out     Master_PIC_Command, al
        popad
        iret

irq#80_syscall:
        pushad
    
    ; Pongo en 1 el flag de syscall en proceso de la tarea que corresponda    
        mov     eax, [current_task]
        cmp     eax, 0x01
        jne     not_t1_running
            mov     dword [at_syscall_t1], 0x01
        not_t1_running:

        cmp     eax, 0x02
        jne     not_t2_running
            mov     dword [at_syscall_t2], 0x01
        not_t2_running:
        
        cmp     eax, 0x03
        jne     not_t3_running
            mov     dword [at_syscall_t3], 0x01
        not_t3_running:

        
    ; Traigo la pila de PL=3
        mov     ebp, esp
        mov     esi, [ebp + 0x2C]                   

    ; Saco el primer elemento.
        mov     ecx, [esi]

    ; Si es halt..
        cmp     ecx, td3_halt
        je      m_td3_halt

    ; Si es Print..
        cmp     ecx, td3_print
        je      m_td3_print

    ; Si es Read...
        cmp     ecx, td3_read
        je      m_td3_read

    finish_syscall:
        mov     eax, [current_task]
        cmp     eax, 0x01
        jne     not_t1_running_0
            mov     dword [at_syscall_t1], 0x00
        not_t1_running_0:

        cmp     eax, 0x02
        jne     not_t2_running_0
            mov     dword [at_syscall_t2], 0x00
        not_t2_running_0:
        
        cmp     eax, 0x03
        jne     not_t3_running_0
            mov     dword [at_syscall_t3], 0x00
        not_t3_running_0:

        popad
        iret

;______________________________________________________________________________;
;                           Funciones de Syscall                               ;
;______________________________________________________________________________;

;________________________________________
; Funcion Halt
;________________________________________
m_td3_halt:
        mov     eax, [current_task]
        cmp     eax, 0x01
        jne     not_t1_finish
            mov     dword [task1_end_flag], 0x01
        not_t1_finish:

        cmp     eax, 0x02
        jne     not_t2_finish
            mov     dword [task2_end_flag], 0x01
        not_t2_finish:
        
        cmp     eax, 0x03
        jne     not_t3_finish
            mov     dword [task3_end_flag], 0x01
        not_t3_finish:

        sti                                             ; Enciendo las interrupciones.
        hlt
        ;jmp     m_td3_halt
        jmp     finish_syscall                          ; Me voy de la syscall.


;________________________________________
; Funcion Print
;________________________________________
m_td3_print:
        sti                                             ; Enciendo las interrupciones.

    ; Chequeo cantidad de bytes.
        mov     ebx, [esi + 0x08]                       ; Obtengo la cantidad de bytes de la pila de PL=3.
        cmp     ebx, 0x02
        je      print_buffer                            ; Si la cantidad es diferente a 2 bytes termino la syscall.
            jmp     print_error                          
        print_buffer:

    ; Chequeo que la ubicacion del buffer este permitida para la tarea.
        mov     edx, [esi + 4]                          ; Saco el buffer a imprimir de la pila de PL=3.

        ; Si se trata de la Tarea 1.
        cmp     eax, 0x01
        jne     not_t1_print
            cmp     edx, __TASK1_DATA_RW_LIN            ; Si el buffer esta por debajo de la zona permitida, me voy.
            jl      print_error
            cmp     edx, __TASK1_DATA_RW_END - 4        ; Si el buffer esta por arriba de la zona permitida, me voy.
            jg      print_error                         ;   (la ultima posicion posible es la del final - 4).

            push    task1_id                            ; Identificador de Tarea a imprimir.
            push    num_row_offset                      ; Fila donde se imprimira.
            push    num_column_offset                   ; Columna donde se imprimira.
            push    edx                                 ; Buffer a imprimir.
            call    print_result                        ; Llamo a la funcion.
            pop     eax
            pop     eax
            pop     eax
            pop     eax
        not_t1_print:

        ; Si se trata de la Tarea 2.
        cmp     eax, 0x02
        jne     not_t2_print
            cmp     edx, __TASK2_DATA_RW_LIN            ; Si el buffer esta por debajo de la zona permitida, me voy.
            jl      print_error
            cmp     edx, __TASK2_DATA_RW_END - 4        ; Si el buffer esta por arriba de la zona permitida, me voy.
            jg      print_error                         ;   (la ultima posicion posible es la del final - 4).

            push    task2_id                            ; Identificador de Tarea a imprimir.
            push    num_row_offset_2                    ; Fila donde se imprimira.
            push    num_column_offset_2                 ; Columna donde se imprimira.
            push    edx                                 ; Buffer a imprimir.
            call    print_result                        ; Llamo a la funcion.
            pop     eax
            pop     eax
            pop     eax
            pop     eax
        not_t2_print:

    ; Salida con error.
    print_error:
        mov     dword [esi + 0x0C], 0x01                ; Valor de retorno = 1 (con error).
        jmp     finish_syscall                          ; Me voy de la syscall.


;________________________________________
; Funcion Read
;________________________________________
m_td3_read:
    ; Chequeo que haya pendiente un dato.
        mov     ebx, [esi + 0x08]                       ; Saco el indice a leer de la pila de PL=3.
        mov     ecx, [saved_digits_table_index]         ; Traigo el indice de la tabla

        cmp     ecx, ebx                                ; Si son iguales no hay datos que leer.
        je      no_new_data

    ; Chequeo que la ubicacion del buffer este permitida para la tarea.
            mov     edx, [esi + 4]                          ; Saco el buffer a imprimir de la pila de PL=3.
            ; Si se trata de la Tarea 1.
            cmp     eax, 0x01
            jne     not_t1_data
                cmp     edx, __TASK1_DATA_RW_LIN            ; Si el buffer esta por debajo de la zona permitida, me voy.
                jl      no_new_data
                cmp     edx, __TASK1_DATA_RW_END - 4        ; Si el buffer esta por arriba de la zona permitida, me voy.
                jg      no_new_data                         ;   (la ultima posicion posible es la del final - 4).

                mov     ecx, [saved_digits_table + ebx]         ; Leo parte baja
                mov     ebx, [saved_digits_table + ebx + 0x04]  ; Leo parte alta
                jmp     new_data
            not_t1_data:


            jmp no_new_data
        
    new_data:
;BKPT
        mov     [edx], ecx  ; Escribo la parte baja
        mov     [edx + 4], ebx ; Escribo la parte alta

        mov     dword [esi + 0x0C], 0x00            ; Valor de retorno = 0 (dato leido).
        jmp     finish_syscall                      ; Me voy de la syscall.

    ; Me voy de la syscall, ya sea porque no hay nada que leer o porque el buffer 
    ;   es de una zona de memoria no permitida.
    no_new_data:
        mov     dword [esi + 0x0C], 0x01            ; Valor de retorno = 1 (nada que leer).
        jmp     finish_syscall                      ; Me voy de la syscall.