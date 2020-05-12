;Mucha mas info aca: https://wiki.osdev.org/PIT

%define BKPT    xchg    bx,bx

GLOBAL timer_count
GLOBAL timer_routine

;______________________________________________________________________________;
;                           Contador de timer                                  ;
;______________________________________________________________________________;

section .timer_count nobits
    timer_count:
        resb 2



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
    cmp     eax, 0xFFF
    jnz     continue
        xor     eax,eax
        BKPT
    continue:
    mov     [timer_count], ax
    popad
    ret
