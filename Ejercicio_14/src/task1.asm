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
    sum_stored:
        resb 8
    last_index_sum:
        resd 1
    task1_end_flag:
        resd 1

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;
section .task_one
sum_routine:
        mov     eax, [last_index_sum]
        cmp     [saved_digits_table_index], eax             ; Me fijo si este numero ya lo sume. Me voy si lo hice.
        je      sum_end
            mov     edi, [saved_digits_table_index]         ; Indice de la tabla. Apunta al ultimo numero guardado.
            mov     [last_index_sum], edi                 ; Guardo el indice del ultimo numero que sume.
            mov     eax, [saved_digits_table + edi - 8]     ; Traigo la parte baja del ultimo numero ingresado.
            mov     ebx, [saved_digits_table + edi - 4]     ; Traigo la parte alta del ultimo numero ingresado.
            mov     ecx, [sum_stored]                       ; Traigo la parte baja de la suma previamente almacenada
            mov     edx, [sum_stored + 4]                   ; Traigo la parte alta de la suma previamente almacenada
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
            mov     [sum_stored], ecx                       ; Guardo la parte baja en la posicion pedida.
            mov     [sum_stored + 4], edx                   ; Guardo la parte alta en la posicion pedida.

            ;[EJERCICIO 12]
            ;cmp     edx, 0x00                               ; Si la parte alta es mayor a 0 es mas que 512MB, me voy.
            ;jg      sum_end
            ;cmp     ecx, 0x20000000                         ; Si la parte baja es mayor a 512MB, me voy.
            ;jg      sum_end

            ;mov     eax, [ecx]                              ; Intento leer la posicion de memoria menor a 512MB

        sum_end:
        mov     dword [task1_end_flag], 0x01
        hlt
        jmp     sum_end
