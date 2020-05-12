;Mucha mas info aca: 

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
    xor     eax, eax
    mov     eax, [timer_count]
    inc     eax
    mov     [timer_count], eax
    ;BKPT
    ;xor eax,eax
    popad
    ret
