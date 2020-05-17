%define BKPT    xchg    bx,bx

GLOBAL sum_routine

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
section .sum_stored nobits
    sum_stored:
        resb 8

;______________________________________________________________________________;
;                               Tarea suma.                                    ;
;______________________________________________________________________________;

section .task_one
sum_routine:
        pushad
        mov     ax, [timer_flag]
        mov     bx, [enter_key_flag]
        cmp     ax, 0x00                                ; Chequeo que este el flag de timer.
        jz      sum_end
        cmp     bx, 0x00                                ; Chequeo que este el flag de enter.
        jz      sum_end

        mov     ax, 0x00
        mov     [timer_flag], ax                        ; Pongo en cero los flags.
        mov     [enter_key_flag], ax

        mov     edi, [saved_digits_table_index]
        mov     eax, [saved_digits_table + edi - 8]     ; Traigo la parte baja del ultimo numero ingresado.
        mov     ebx, [saved_digits_table + edi - 4]     ; Traigo la parte alta del ultimo numero ingresado.
        mov     ecx, [sum_stored]                       ; Traigo la parte baja de la suma previamente almacenada
        mov     edx, [sum_stored + 4]                   ; Traigo la parte alta de la suma previamente almacenada
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
        mov     [sum_stored], ecx                       ; Guardo en la posicion pedida.
        mov     [sum_stored + 4], edx
        BKPT

    sum_end:
        popad
        ret
