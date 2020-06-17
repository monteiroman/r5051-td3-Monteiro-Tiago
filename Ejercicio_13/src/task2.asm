%define BKPT    xchg    bx,bx

GLOBAL sum_routine_2
GLOBAL sum_stored_2

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

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;

section .task_two
sum_routine_2:
        mov     ax, [timer_flag_2]
        mov     bx, [enter_key_flag_2]
        cmp     ax, 0x00                                ; Chequeo que este el flag de timer.
        jz      sum_end
        cmp     bx, 0x00                                ; Chequeo que este el flag de enter.
        jz      sum_end

        mov     ax, 0x00
        mov     [timer_flag_2], ax                      ; Pongo en cero los flags.
        mov     [enter_key_flag_2], ax

        mov     edi, [saved_digits_table_index]
        mov     eax, [saved_digits_table + edi - 8]     ; Traigo la parte baja del ultimo numero ingresado.
        mov     ebx, [saved_digits_table + edi - 4]     ; Traigo la parte alta del ultimo numero ingresado.
        mov     ecx, [sum_stored_2]                     ; Traigo la parte baja de la suma previamente almacenada
        mov     edx, [sum_stored_2 + 4]                 ; Traigo la parte alta de la suma previamente almacenada
        ;BKPT

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

    sum_end:
        ret
