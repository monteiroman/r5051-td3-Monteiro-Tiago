%define BKPT    xchg    bx,bx

%define Master_PIC_Command  0x20

GLOBAL irq#01_keyboard_handler
GLOBAL irq#00_timer_handler
GLOBAL m_scheduler_int_end

; Desde keyboard.asm
EXTERN keyboard_routine

; Desde timer.asm
EXTERN timer_routine

; Desde Scheduler
EXTERN m_scheduler

USE32

section .irq_handlers

irq#00_timer_handler:
    ;pushad
    ;call    timer_routine
    jmp     m_scheduler
    m_scheduler_int_end:

    push    eax                 ; Pusheo a pila eax porq lo voy a usar para otra cosa

    mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion
    out     Master_PIC_Command, al

    pop     eax                 ; para mantener el eax del contexto
    ;popad
    iret

irq#01_keyboard_handler:
    pushad
    call    keyboard_routine
    mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion
    out     Master_PIC_Command, al
    popad
    iret
