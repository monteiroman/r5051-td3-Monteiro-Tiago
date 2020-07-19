%define BKPT        xchg    bx,bx
%define m_syscall   int     0x80
%define td3_halt    0x11
%define td3_read    0x22
%define td3_print   0x33 

GLOBAL sum_routine_2
GLOBAL sum_stored_2

; Desde keyboard.asm
EXTERN saved_digits_table
EXTERN saved_digits_table_index

USE32
;______________________________________________________________________________;
;                          Resultado de la suma                                ;
;______________________________________________________________________________;
section .task2_data nobits
ALIGN 512
    last_index_sum_2:
        resd 1
    sum_buffer_2:
        resb 8
    sum_stored_2:
        resb 8

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;
section .task_two
sum_routine_2:
        
        mov     eax, [last_index_sum_2]
    ; Me fijo si hay algo para leer antes de entrar al loop. Es decir, si los indices "last_index_sum" (el de la tarea)
    ;   y "saved_digits_table_index" (el de la lista de numeros) son diferentes.
        push    dword 0x00
        push    eax                                         ; Ultimo numero sumado.
        push    sum_buffer_2                                  ; Si habia algo me lo devuelve aca.
        push    td3_read
        m_syscall
        pop     ebx
        pop     ebx
        pop     ebx
        pop     ebx                                         ; Valor de retorno.

    ; Loop de suma. Si habia mas de un valor al momento de ejecutar la tarea se suman todos.
        cmp     ebx, 0x01                                   ; No habia nada para leer, me voy.
        je      sum_end_2

            sum_loop_2:
            mov     ecx, [last_index_sum_2]                 ; Me muevo 8 bytes en el indice del numero que sume (proximo
            add     ecx, 0x08                               ;   numero).
            mov     [last_index_sum_2], ecx                 ; Guardo el indice en memoria.

            movdqu  xmm0, [sum_buffer_2]                    ; Numero de la tabla de digitos.
            movdqu  xmm1, [sum_stored_2]                    ; Traigo la suma previa.

            paddw   xmm0, xmm1                              ; Sumo.

            movdqu  [sum_stored_2], xmm0                    ; Guardo la suma.

            push    dword 0x00
            push    ecx
            push    sum_buffer_2                            ; Si habia algo me lo devuelve aca.
            push    td3_read
            m_syscall
            pop     ebx
            pop     ebx
            pop     ebx
            pop     ebx                                     ; Valor de retorno.

            cmp     ebx, 0x01                               ; Si no hay mas que sumar (recibi un 1), me voy.
            jne     sum_loop_2                              ; Si no llegue al ultimo vuelvo a sumar.

        sum_end_2:
    ; Imprimo en pantalla  
        push    dword 0x00                                  ; Posicion en la pila del valor de retorno.
        push    dword 0x02                                  ; Cantidad de Bytes del puntero.
        push    sum_stored_2                                ; Puntero de memoria a imprimir.
        push    td3_print                                   ; Funcion a ejecutar.
        m_syscall                                           ; Llamo a la syscall
        pop     eax
        pop     eax
        pop     eax
        pop     eax

    ; Pongo el procesador en Halt
        push    dword td3_halt
        m_syscall
        pop     eax
        jmp     sum_end_2

