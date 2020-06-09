;Mucha mas info aca: https://wiki.osdev.org/PIT

%define BKPT    xchg    bx,bx

GLOBAL timer_routine
GLOBAL timer_count
GLOBAL timer_flag
GLOBAL timer_flag_2

;______________________________________________________________________________;
;                           Rutina del timer                                   ;
;______________________________________________________________________________;

;________________________________________
; Bytes de cuentas de timer y
; flags.
;________________________________________
section .counter_bytes nobits               ; Las variables usadas son mucho mas
    timer_count:                            ; grandes de lo necesario para que se
        resb 4                              ; vean bien las tablas en el Bochs
    timer_flag:
        resb 4
    timer_flag_2:
        resb 4


;________________________________________
; Tabla para guardar los digitos
;________________________________________

section .timer
timer_routine:
    pushad
    xor     eax, eax
    mov     ax, [timer_count]
    inc     eax
    cmp     eax, 0x32                   ; El timer interrumpe cada 10ms
    jnz     continue                    ;           -> 500ms / 10ms = 50 = 0x32
        xor     eax,eax
        mov word    [timer_flag], 0x01   ; Una vez terminada la cuenta pongo a 1 el flag1
        mov word    [timer_flag_2], 0x01 ; Una vez terminada la cuenta pongo a 1 el flag2
        ;BKPT                           ;   el flag.
    continue:
    mov     [timer_count], ax
    popad
    ret
