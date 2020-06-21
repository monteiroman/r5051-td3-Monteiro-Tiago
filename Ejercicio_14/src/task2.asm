%define BKPT    xchg    bx,bx

GLOBAL sum_routine_2
GLOBAL sum_stored_2
GLOBAL task2_end_flag

; Desde keyboard.asm
EXTERN saved_digits_table
EXTERN saved_digits_table_index
EXTERN enter_key_flag_2

; Desde timer.asm
EXTERN timer_flag_2

USE32
;______________________________________________________________________________;
;                          Resultado de la suma                                ;
;______________________________________________________________________________;
section .sum_store_2 nobits
    sum_stored_2:
        resb 8
    last_index_sum_2:
        resd 1
    task2_end_flag:
        resd 1

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;
section .task_two
sum_routine_2:
;BKPT
        mov     eax, [last_index_sum_2]
        cmp     [saved_digits_table_index], eax             ; Me fijo si este numero ya lo sume. Me voy si lo hice.
        je      sum_end_2
            mov     edi, [saved_digits_table_index]         ; Indice de la tabla. Apunta al ultimo numero guardado.
            mov     [last_index_sum_2], edi                 ; Guardo el indice del ultimo numero que sume.
            mov     eax, [saved_digits_table + edi - 8]     ; Traigo la parte baja del ultimo numero ingresado.
            mov     ebx, [saved_digits_table + edi - 4]     ; Traigo la parte alta del ultimo numero ingresado.
            mov     ecx, [sum_stored_2]                     ; Traigo la parte baja de la suma previamente almacenada
            mov     edx, [sum_stored_2 + 4]                 ; Traigo la parte alta de la suma previamente almacenada
            add     ecx, eax                                ; Sumo, si tengo carry lo considero.
            jc      carry
            jnc     not_carry

            carry:
            adc     edx, ebx
            jmp     save

            not_carry:
            add     edx, ebx
            jmp     save

            save:
            mov     [sum_stored_2], ecx                     ; Guardo la parte baja en la posicion pedida.
            mov     [sum_stored_2 + 4], edx                 ; Guardo la parte alta en la posicion pedida.

        sum_end_2:
        mov     dword [task2_end_flag], 0x01
        hlt
        jmp     sum_end_2