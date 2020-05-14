;Mucha mas info aca: https://wiki.osdev.org/PIT

%define BKPT    xchg    bx,bx

GLOBAL timer_routine

;Desde Keyboard
EXTERN timer_count


;______________________________________________________________________________;
;                           Rutina del timer                                   ;
;______________________________________________________________________________;

section .timer
timer_routine:
    pushad
    ;BKPT
    xor     eax, eax
    mov     ax, [timer_count]
    inc     eax
    cmp     eax, 0xFFFF
    jnz     continue
        xor     eax,eax
        BKPT
    continue:
    mov     [timer_count], ax
    popad
    ret
