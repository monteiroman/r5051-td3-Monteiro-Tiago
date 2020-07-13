%define BKPT        xchg    bx,bx
%define m_syscall   int     0x80
%define td3_halt    0x11
%define td3_read    0x22
%define td3_print   0x33 

GLOBAL sum_routine
GLOBAL sum_stored
;GLOBAL task1_end_flag

; Desde keyboard.asm
EXTERN saved_digits_table
EXTERN saved_digits_table_index
EXTERN enter_key_flag

; Desde timer.asm
EXTERN timer_flag

; esto despues hay que sacarlo
EXTERN task1_end_flag

USE32
;______________________________________________________________________________;
;                          Resultado de la suma                                ;
;______________________________________________________________________________;
section .task1_data nobits
ALIGN 512
    last_index_sum:
        resd 1
    sum_buffer:
        resb 8
    sum_stored:
        resb 8

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;
section .task_one
sum_routine:

        mov     eax, [last_index_sum]
    ; Me fijo si hay algo para leer antes de entrar al loop. Es decir, si los indices "last_index_sum" (el de la tarea)
    ;   y "saved_digits_table_index" (el de la lista de numeros) son diferentes.
        push    dword 0x00
        push    eax                                         ; Ultimo numero sumado.
        push    sum_buffer                                  ; Si habia algo me lo devuelve aca.
        push    td3_read
        m_syscall
        pop     ebx
        pop     ebx
        pop     ebx
        pop     ebx                                         ; Valor de retorno.

    ; Loop de suma. Si habia mas de un valor al momento de ejecutar la tarea se suman todos.
        cmp     ebx, 0x01                                   ; No habia nada para leer, me voy.
        je      sum_end

            sum_loop:
            mov     ecx, [last_index_sum]                   ; Me muevo 8 bytes en el indice del numero que sume (proximo
            add     ecx, 0x08                               ;   numero).
            mov     [last_index_sum], ecx                   ; Guardo el indice en memoria.

            movdqu  xmm0, [sum_buffer]                      ; Numero de la tabla de digitos.
            movdqu  xmm1, [sum_stored]                      ; Traigo la suma previa.

            paddq   xmm0, xmm1                              ; Sumo.

            movdqu  [sum_stored], xmm0                      ; Guardo la suma.

            ;   vvv---[EJERCICIO 12]---vvv
            ;cmp     edx, 0x00                               ; Si la parte alta es mayor a 0 es mas que 512MB, me voy.
            ;jg      sum_end
            ;cmp     ecx, 0x20000000                         ; Si la parte baja es mayor a 512MB, me voy.
            ;jg      sum_end

            ;mov     eax, [ecx]                              ; Intento leer la posicion de memoria menor a 512MB
            ;   ^^^---[EJERCICIO 12]---^^^

            push    dword 0x00
            push    ecx
            push    sum_buffer                              ; Si habia algo me lo devuelve aca.
            push    td3_read
            m_syscall
            pop     ebx
            pop     ebx
            pop     ebx
            pop     ebx                                     ; Valor de retorno.

            cmp     ebx, 0x01                               ; Si no hay mas que sumar (recibi un 1), me voy.
            jne     sum_loop                                ; Si no llegue al ultimo vuelvo a sumar.

        sum_end:
    ; Imprimo en pantalla  
        push    dword 0x00                                  ; Posicion en la pila del valor de retorno.
        push    dword 0x02                                  ; Cantidad de Bytes del puntero.
        push    sum_stored                                  ; Puntero de memoria a imprimir.
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
        jmp     sum_end
