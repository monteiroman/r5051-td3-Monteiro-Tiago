%define BKPT    xchg    bx,bx

GLOBAL idle_task


;______________________________________________________________________________;
;                               Tarea Idle.                                    ;
;______________________________________________________________________________;
USE32

section .task_three
idle_task:
        mov     eax, 0x6969
        BKPT
        ;hlt
        ret
        jmp     idle_task