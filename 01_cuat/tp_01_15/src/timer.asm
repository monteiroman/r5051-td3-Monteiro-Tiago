;Mucha mas info aca: https://wiki.osdev.org/PIT

%define BKPT    xchg    bx,bx

GLOBAL timer_routine
GLOBAL timer_count
GLOBAL timer_flag
GLOBAL timer_flag_2
GLOBAL timer_splash_flag

; Desde scheduler.asm
EXTERN future_task
EXTERN current_task
EXTERN change_context

;______________________________________________________________________________;
;                           Rutina del timer                                   ;
;______________________________________________________________________________;

;________________________________________
; Bytes de cuentas de timer y
; flags.
;________________________________________
section .counter_bytes nobits               ; Las variables usadas son mucho mas
    timer_count:                            ; grandes de lo necesario para que se
        resb 4                              ; vean bien las tablas en el Bochs
    timer_count_2: 
        resb 4
    timer_flag:
        resb 4
    timer_flag_2:
        resb 4
    timer_splash:
        resb 4
    timer_splash_flag:
        resb 4   


;________________________________________
; Interrupcion de timer
;________________________________________

section .timer
timer_routine:
    pushad

    ; Contador de Tarea 1
    xor     eax, eax
    mov     ax, [timer_count]
    inc     eax
    cmp     eax, 0x0A                       ; El timer interrumpe cada 10ms
    jnz     continue                        ;           -> 100ms / 10ms = 10 = 0x0A
        xor     eax,eax
        mov word    [timer_flag], 0x01      ; Una vez terminada la cuenta pongo a 1 el flag1
    continue:
    mov     [timer_count], ax

    ; Contador de Tarea 2
    xor     eax, eax
    mov     ax, [timer_count_2]
    inc     eax
    cmp     eax, 0x14                         ; El timer interrumpe cada 10ms
    jnz     continue_2                        ;           -> 200ms / 10ms = 20 = 0x14
        xor     eax,eax
        mov word    [timer_flag_2], 0x01      ; Una vez terminada la cuenta pongo a 1 el flag1
    continue_2:
    mov     [timer_count_2], ax
    
    ; Contador de Splash
    xor     eax, eax
    mov     ax, [timer_splash]
    cmp     ax, 0x275                           
    jl      sum_splash                          
         mov    word [timer_splash_flag], 0x01  ; Una vez terminada la cuenta pongo a 1 el flag.
         jmp    end_splash_count
    sum_splash:
    inc     word [timer_splash]
    end_splash_count:
    
    popad
    ret
