%define BKPT    xchg    bx,bx

GLOBAL sum_routine
GLOBAL sum_stored

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
        mov     [sum_stored], ecx                       ; Guardo la parte baja en la posicion pedida.
        mov     [sum_stored + 4], edx                   ; Guardo la parte alta en la posicion pedida.

        cmp     edx, 0x01                               ; Si la parte alta es mayor a 1 es mas que 512MB, me voy.
        jg      sum_end
        cmp     ecx, 0x20000000                         ; Si la parte baja es mayor a 512MB, me voy.
        jg      sum_end

        mov     eax, [ecx]                              ; Intento leer la posicion de memoria menor a 512MB
        ;BKPT

    sum_end:
        popad
        ret
