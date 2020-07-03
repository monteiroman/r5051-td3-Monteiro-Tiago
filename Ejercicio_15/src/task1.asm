%define BKPT    xchg    bx,bx

GLOBAL sum_routine
GLOBAL sum_stored
GLOBAL task1_end_flag

; Desde keyboard.asm
EXTERN saved_digits_table
EXTERN saved_digits_table_index
EXTERN enter_key_flag

; Desde timer.asm
EXTERN timer_flag

USE32
;______________________________________________________________________________;
;                          Resultado de la suma                                ;
;______________________________________________________________________________;
section .sum_store nobits
ALIGN 512
    last_index_sum:
        resd 1
    task1_end_flag:
        resd 1
    sum_stored:
        resb 8

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;
section .task_one
sum_routine:
        mov     eax, [last_index_sum]
        cmp     [saved_digits_table_index], eax             ; Me fijo si este numero ya lo sume. Me voy si lo hice.
        je      sum_end
            sum_loop:
            mov     edi, [last_index_sum]                   ; Traigo de nuevo el ultimo numero que sume.
            add     edi, 0x08                               ; Le sumo 8 para que pase al siguiente numero.
            mov     [last_index_sum], edi                   ; Guardo el indice en memoria.

            movdqu  xmm0, [saved_digits_table + edi - 8]    ; Traigo el numero siguiente al ultimo que ingrese
            movdqu  xmm1, [sum_stored]                      ; Traigo la suma previa.

            paddq   xmm0, xmm1                              ; Sumo.

            movdqu  [sum_stored], xmm0                      ; Guardo la suma.

            ;[EJERCICIO 12]
            ;cmp     edx, 0x00                               ; Si la parte alta es mayor a 0 es mas que 512MB, me voy.
            ;jg      sum_end
            ;cmp     ecx, 0x20000000                         ; Si la parte baja es mayor a 512MB, me voy.
            ;jg      sum_end

            ;mov     eax, [ecx]                              ; Intento leer la posicion de memoria menor a 512MB

            mov     eax, [saved_digits_table_index]         ; Traigo el indice de la tabla.
            cmp     edi, eax                                ; Lo comparo con el del ultimo numero que sume.
            jne     sum_loop                                ; Si no llegue al ultimo vuelvo a sumar.

        sum_end:
        mov     dword [task1_end_flag], 0x01
        hlt
        jmp     sum_end
