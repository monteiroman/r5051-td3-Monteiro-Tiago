%define BKPT        xchg    bx,bx
%define m_syscall   int     0x80
%define td3_halt    0x11
%define td3_read    0x22
%define td3_print   0x33


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
        push    dword td3_halt
        m_syscall
        pop     eax
        ;hlt
        ;BKPT
        jmp     idle_task