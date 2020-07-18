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

        push    dword td3_halt
        m_syscall
        pop     eax
 
        jmp     idle_task