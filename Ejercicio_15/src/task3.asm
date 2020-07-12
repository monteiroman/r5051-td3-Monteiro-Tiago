%define BKPT        xchg    bx,bx
%define m_syscall   int     0x80

GLOBAL idle_task




;______________________________________________________________________________;
;                               Tarea Idle.                                    ;
;______________________________________________________________________________;
USE32

section .task_three
idle_task:
        mov     eax, 0x6969
        mov     ebx, 0x8888
;BKPT
        
        m_syscall
        ;hlt
        ;BKPT
        jmp     idle_task