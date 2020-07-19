%define BKPT    xchg    bx,bx

%define Master_PIC_Command  0x20

GLOBAL irq#01_keyboard_handler
GLOBAL irq#00_timer_handler

;Desde keyboard.asm
EXTERN keyboard_routine

;Desde timer.asm
EXTERN timer_routine


USE32

section .irq_handlers

irq#00_timer_handler:
    pushad
    call    timer_routine
    mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion
    out     Master_PIC_Command, al
    popad
    iret

irq#01_keyboard_handler:
    pushad
    call    keyboard_routine
    mov     al, 0x20            ; Le viso al pic que ya trate la interrupcion
    out     Master_PIC_Command, al
    popad
    iret
