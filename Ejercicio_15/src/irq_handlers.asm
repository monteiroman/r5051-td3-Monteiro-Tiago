%define BKPT    xchg    bx,bx

%define Master_PIC_Command  0x20

%define td3_halt    0x11
%define td3_read    0x22
%define td3_print   0x33

GLOBAL irq#01_keyboard_handler
GLOBAL irq#00_timer_handler
GLOBAL irq#80_syscall
GLOBAL m_scheduler_int_end

; Desde keyboard.asm
EXTERN keyboard_routine

; Desde timer.asm
EXTERN timer_routine

; Desde Scheduler
EXTERN m_scheduler

; Desde scheduler.asm
EXTERN current_task
EXTERN at_syscall_t1
EXTERN at_syscall_t2
EXTERN at_syscall_t3

USE32

;______________________________________________________________________________;
;                       Manejadores de interrupciones                          ;
;______________________________________________________________________________;
section .irq_handlers

irq#00_timer_handler:
        call    timer_routine
    
        jmp     m_scheduler         ; Voy al scheduler (ver scheduler.asm).
        m_scheduler_int_end:        ; Punto de retorno

        push    eax                 ; Pusheo a pila eax porq lo voy a usar para otra cosa.

        mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion.
        out     Master_PIC_Command, al

        pop     eax                 ; Popeo para mantener el eax del contexto.
        iret

irq#01_keyboard_handler:
        pushad
        call    keyboard_routine    ; Ver keyboard.asm.
        mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion
        out     Master_PIC_Command, al
        popad
        iret

irq#80_syscall:
        pushad
    
    ; Pongo en 1 el flag de syscall en proceso de la tarea que corresponda    
        mov     eax, [current_task]
        cmp     eax, 0x01
        jne     not_t1_running
            mov     edi, at_syscall_t1
        not_t1_running:

        cmp     eax, 0x02
        jne     not_t2_running
            mov     edi, at_syscall_t2
        not_t2_running:
        
        cmp     eax, 0x03
        jne     not_t3_running
            mov     edi, at_syscall_t3
        not_t3_running:

        ; Seteo el flag.
        mov     dword [edi], 0x01

        
        mov     ebp, esp
        mov     esi, [ebp + 0x2C]                   ; Traigo la pila de PL=3
        mov     eax, esi                            ; Saco el primer elemento.

        cmp     eax, td3_halt
        jmp     m_td3_halt


        finish_syscall:
        mov     dword [edi], 0x00                   ; Reseteo el flag de syscall en proceso.
        popad
        iret

;______________________________________________________________________________;
;                           Funciones de Syscall                               ;
;______________________________________________________________________________;

;________________________________________
; Funcion Halt
;________________________________________
m_td3_halt:
        sti
        hlt
        jmp     m_td3_halt
        jmp     finish_syscall