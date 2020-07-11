%define BKPT    xchg    bx,bx

%define Master_PIC_Command  0x20

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
BKPT
        popad
        iret

;______________________________________________________________________________;
;                           Funciones de Syscall                               ;
;______________________________________________________________________________;