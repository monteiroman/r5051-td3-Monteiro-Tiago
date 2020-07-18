; Mas información aca: http://wiki.electron.frba.utn.edu.ar/doku.php?id=td3:switchto

%define BKPT    xchg    bx,bx

; Indices de mi TSS
%define m_backlink_idx  0x00
%define m_esp0_idx      0x04
%define m_ss0_idx       0x08
%define m_esp1_idx      0x0C
%define m_ss1_idx       0x10
%define m_esp2_idx      0x14
%define m_ss2_idx       0x18
%define m_CR3_idx       0x1C
%define m_eip_idx       0x20
%define m_eflags_idx    0x24
%define m_eax_idx       0x28
%define m_ecx_idx       0x2C
%define m_edx_idx       0x30
%define m_ebx_idx       0x34
%define m_esp_idx       0x38
%define m_ebp_idx       0x3C
%define m_esi_idx       0x40
%define m_edi_idx       0x44
%define m_es_idx        0x48
%define m_cs_idx        0x4C
%define m_ss_idx        0x50
%define m_ds_idx        0x54
%define m_fs_idx        0x58
%define m_gs_idx        0x5C
%define m_ldtr_idx      0x60
%define m_bitmapIO_idx  0x64

GLOBAL scheduler_init
GLOBAL current_task
GLOBAL future_task
GLOBAL m_scheduler

; Desde keyboard.asm
EXTERN enter_key_flag                         ; Al enter lo considero como inicio de mi tarea
EXTERN enter_key_flag_2

; Desde timer.asm
EXTERN timer_flag                             ; El timer me va a decir si se puede ejecutar o no
EXTERN timer_flag_2

; Desde biosLS.lds
EXTERN __TASK1_STACK_END
EXTERN __TASK2_STACK_END
EXTERN __TASK3_STACK_END

; Desde paging.asm
EXTERN kernel_page_directory
EXTERN task1_page_directory
EXTERN task2_page_directory
EXTERN task3_page_directory

; Desde irq_handlers.asm
EXTERN m_scheduler_int_end

; Desde task1.asm
EXTERN sum_routine

; Desde task2.asm
EXTERN sum_routine_2

; Desde task3.asm
EXTERN idle_task

; Desde screen.asm
EXTERN refresh_screen

USE32
;______________________________________________________________________________;
;                                 Scheduler                                    ;
;______________________________________________________________________________;
section .scheduler

;________________________________________
; Inicializacion del Scheduler
;________________________________________
scheduler_init:
        mov     dword [current_task], 0x00          ; Me voy del Kernel
        mov     dword [future_task], 0x03           ; A la tarea idle

        call    contexts_init

        pushfd                                      ; Pusheo flags                  |
        push    cs                                  ; Pusheo Code Segment           |   Lo hago asi de entrada porque es
        push    m_scheduler                         ; Pusheo dirección de destino   |   asi como va a funcionar siempre
                                                    ; La proxima vez que entre al   |   mi funcion.
                                                    ; kernel tengo que decidir que  |
                                                    ; Tarea se ejecutara y eso lo   |
                                                    ; hago desde "m_scheduler"      |
        jmp     m_scheduler                         ; salto                         |   


;________________________________________
; Scheduler
;________________________________________
m_scheduler:
    ; Guardo el contexto de la tarea saliente __________________________________________________________________________
        push    eax                                     ; Guardo eax en la pila para usarlo de 

        cmp     dword [current_task], 0x00              ; Me fijo si vengo desde Kernel
        jne     not_kernel
            mov     eax, m_tss_kernel                   ; Guardo la dirección del contexto de Kernel
            jmp     save_context
        not_kernel:                         

        cmp     dword [current_task], 0x01              ; Me fijo si vengo desde la Tarea 1
        jne     not_task1
            mov     eax, m_tss_1                        ; Guardo la dirección del contexto de Tarea 1
            jmp     save_context
        not_task1:

        cmp     dword [current_task], 0x02              ; Me fijo si vengo desde la Tarea 2
        jne     not_task2
            mov     eax, m_tss_2                        ; Guardo la dirección del contexto de Tarea 2
            jmp     save_context
        not_task2:

        cmp     dword [current_task], 0x03              ; Me fijo si vengo desde la Tarea 3
        jne     not_task3
            mov     eax, m_tss_3                        ; Guardo la dirección del contexto de Tarea 3
            jmp     save_context
        not_task3:                                         

        save_context:                                   ; Guardo el contexto de la tarea que esta por dejar de usarse.
        ; Guardo registros (menos eax que lo guardo al final).
        mov     [eax + m_ebx_idx], ebx
        mov     [eax + m_ecx_idx], ecx
        mov     [eax + m_edx_idx], edx
        mov     [eax + m_ebp_idx], ebp
        mov     [eax + m_esi_idx], esi
        mov     [eax + m_edi_idx], edi

        ; Ya puedo usar los registros, los uso para guardar los selectores de segmentos.
        mov     ebx, [esp + 0x08]                       ; Saco de la pila la direccion donde vendra "cs"
        mov     [eax + m_cs_idx], bx                    ; Lo guardo en el contexto
        mov     [eax + m_ds_idx], ds
        mov     [eax + m_es_idx], es
        mov     [eax + m_fs_idx], fs
        mov     [eax + m_gs_idx], gs
        mov     [eax + m_ss_idx], ss

        ; Guardo eflags
        mov     ebx, [esp + 0x0C]                       ; Saco los eflags de pila
        mov     [eax + m_eflags_idx], ebx               ; Los guardo en el contexto

        ; Guardo eip
        mov     ebx, [esp + 0x04]                       ; Saco de la cola la direccion de reinicio de la tarea
        mov     [eax + m_eip_idx], ebx                  ; la guardo en el contexto

        ; Guardo eax.
        pop     ebx                                     ; Saco el valor de "eax" de pila
        mov     [eax + m_eax_idx], ebx                  ; Lo guardo en el contexto

        pop     ebx                                     ; |
        pop     ebx                                     ; | Balanceo la pila
        pop     ebx                                     ; |

        mov     [eax + m_esp_idx], esp                  ; La guardo en el contexto


    ; Muestro en pantalla ______________________________________________________________________________________________
        call    refresh_screen


    ; Decido que tarea ejecutar ________________________________________________________________________________________
        call    scheduler_logic


    ; Cargo el contexto de la tarea entrante ___________________________________________________________________________
        cmp     dword [future_task], 0x00
        jne     not_kernel_load
            mov     eax, m_tss_kernel                   ; Contexto de kernel
            jmp     load_context
        not_kernel_load:

        cmp     dword [future_task], 0x01
        jne     not_task1_load
            mov     eax, m_tss_1                        ; Contexto de tarea 1
            jmp     load_context
        not_task1_load:

        cmp     dword [future_task], 0x02
        jne     not_task2_load
            mov     eax, m_tss_2                        ; Contexto de tarea 2
            jmp     load_context
        not_task2_load:

        cmp     dword [future_task], 0x03
        jne     not_task3_load
            mov     eax, m_tss_3                        ; Contexto de tarea 3
        not_task3_load:
    
        load_context:
        ; Cargo registros
        mov     ecx, [eax + m_ecx_idx]
        mov     edx, [eax + m_edx_idx]
        mov     ebp, [eax + m_ebp_idx]
        mov     esi, [eax + m_esi_idx]
        mov     edi, [eax + m_edi_idx]

        ; Cargo registros de segmentos (menos cs que va por pila y ss que se carga despues de CR3).
        xor     ebx, ebx
        mov     bx, [eax + m_ds_idx]
        mov     ds, bx
        mov     bx, [eax + m_es_idx]
        mov     es, bx
        mov     bx, [eax + m_fs_idx]
        mov     fs, bx
        mov     bx, [eax + m_gs_idx]
        mov     gs, bx
    
        ; Cargo dirección de pila.    
        mov     esp, [eax + m_esp_idx] 

        ; Cargo CR3
        mov     ebx, [eax + m_CR3_idx]
        mov     CR3, ebx

        ; Cargo ss.
        mov     bx, [eax + m_ss_idx]
        mov     ss, bx    
        
        ; Cargo en la pila los valores que voy a necesitar en el "iret"
        cmp     dword [future_task], 0x03
        je     is_idle_task
            push    m_scheduler_end_task                ; Cuando termine la tarea quiero que vaya a una rutina de 
                                                        ; finalizacion. Esto es solo para las tareas que no son la idle
        is_idle_task:
        mov     ebx, [eax + m_eflags_idx]               ; Pusheo "eflags"            |
        push    ebx                                     ;                            |
        push    dword [eax + m_cs_idx]                  ; Pusheo "cs".               |   Para el "iret".
        mov     ebx, [eax + m_eip_idx]                  ;                            |
        push    ebx                                     ; pusheo "eip".              |


        ; Seteo la tarea actual
        mov     ebx, [future_task]
        mov     [current_task], ebx

        ; Una vez que termino de usar los registros, los completo con los valores del contexto nuevo.
        mov     ebx, [eax + m_ebx_idx]                  ; Cargo el ebx nuevo
        mov     eax, [eax + m_eax_idx]                  ; Cargo el eax nuevo
        
        jmp     m_scheduler_int_end                     ; Vuelvo a irq_handlers.asm


;________________________________________
; Logica del Scheduler
;________________________________________
scheduler_logic:            
        ; Desde el kernel salto a la Tarea 3
        cmp     dword [current_task], 0x00
        jne     not_kernel_round
            mov     dword [future_task], 0x03
            ret
        not_kernel_round:

        ; Desde la Tarea 3 salto a la Tarea 1 o a la Tarea 2 según corresponda.
        cmp     dword [current_task], 0x03
        jne     not_idle_task_round
            ; Salto a Tarea 1
            cmp     dword [enter_key_flag], 0x01
            jne     not_3_to_1
            cmp     dword [timer_flag], 0x01
            jne     not_3_to_1
                mov     dword [future_task], 0x01
                ret
            not_3_to_1:
            ; Salto a Tarea 2
            cmp     dword [enter_key_flag_2], 0x01
            jne     not_3_to_2
            cmp     dword [timer_flag_2], 0x01
            jne     not_3_to_2
                mov     dword [future_task], 0x02
                ret
            not_3_to_2:
        not_idle_task_round:
        
        ; Desde la Tarea 1 salto a la Tarea 2 o a la Tarea 3 según corresponda.
        cmp     dword [current_task], 0x01
        jne     not_task1_round
            ; Salto a Tarea 2
            cmp     dword [enter_key_flag_2], 0x01
            jne     not_1_to_2
            cmp     dword [timer_flag_2], 0x01
            jne     not_1_to_2
                mov     dword [future_task], 0x02
                ret
            not_1_to_2:
            ; Salto a Tarea 3
            cmp     dword [enter_key_flag], 0x00
            jne     not_1_to_3
            cmp     dword [timer_flag], 0x00
            jne     not_1_to_3
                mov     dword [future_task], 0x03       
                ret
            not_1_to_3:
        not_task1_round:
        
        ; Desde la Tarea 2 salto a la Tarea 1 o a la Tarea 3 según corresponda.
        cmp     dword [current_task], 0x02
        jne     not_task2_round
            ; Salto a Tarea 1
            cmp     dword [enter_key_flag], 0x01
            jne     not_2_to_1
            cmp     dword [timer_flag], 0x01
            jne     not_2_to_1
                mov     dword [future_task], 0x01
                ret
            not_2_to_1:
            ; Salto a Tarea 3
            cmp     dword [enter_key_flag_2], 0x00
            jne     not_2_to_3
            cmp     dword [timer_flag_2], 0x00
            jne     not_2_to_3
                mov     dword [future_task], 0x03       
                ret
            not_2_to_3:
        not_task2_round:

        ret


;________________________________________
; Rutina de finalizacion de tarea
;________________________________________
m_scheduler_end_task:
    ; Debo resetear el "eip" al principio de la tarea si es que no termino por el tick del scheduler
    ; sino por haber llegado a ret. Lo que hago es tunear los valores que tendrían que haber quedado
    ; en la pila si hubiera salido con la interrupcion.
        cmp     dword [current_task], 0x01              ; Para la tarea tarea en ejecucion.
        jne     not_reset_eip_1
            mov     dword [enter_key_flag], 0x00        ; Pongo a cero el flag de enter
            mov     dword [timer_flag], 0x00            ; Pongo a cero el flag de timer
            push    dword 0x200                         ; Pongo eflags con IF habilitado
            push    dword [m_tss_1 + m_cs_idx]          ; Pongo el cs
            push    sum_routine                         ; Pongo la direccion de inicio.
            jmp     m_scheduler                         ; Me voy al scheduler.
        not_reset_eip_1:

        cmp     dword [current_task], 0x02
        jne     not_reset_eip_2
            mov     dword [enter_key_flag_2], 0x00        
            mov     dword [timer_flag_2], 0x00            
            push    dword 0x200
            push    dword [m_tss_2 + m_cs_idx]
            push    sum_routine_2
            jmp     m_scheduler
        not_reset_eip_2:

        ; Por default de carga la tarea idle (no pasa nunca pero por las dudas)
        push    dword 0x200
        push    dword [m_tss_3 + m_cs_idx]
        push    idle_task
        jmp     m_scheduler


;________________________________________
; Rutina de finalizacion de tarea
;________________________________________
contexts_init:
    ; Tarea 1
        mov     eax, m_tss_1

        ; Inicializo CR3
        mov     dword [eax + m_CR3_idx], task1_page_directory

        ; Inicializo segmentos
        mov     [eax + m_cs_idx], cs
        mov     [eax + m_ds_idx], ds
        mov     [eax + m_es_idx], es
        mov     [eax + m_fs_idx], fs
        mov     [eax + m_gs_idx], gs
        mov     [eax + m_ss_idx], ss

        ;Inicializo eip
        mov     dword [eax + m_eip_idx], sum_routine 

        ; Inicializo eflags
        mov     dword [eax + m_eflags_idx], 0x200       ; Por lo menos le pongo el bit 9 (IF) a 1 para que interrumpa el
                                                        ; timer.
        ; Inicializo la pila
        mov     dword [eax + m_esp_idx], __TASK1_STACK_END           


    ; Tarea 2
        mov     eax, m_tss_2

        ; Inicializo CR3
        mov     dword [eax + m_CR3_idx], task2_page_directory

        ; Inicializo segmentos
        mov     [eax + m_cs_idx], cs
        mov     [eax + m_ds_idx], ds
        mov     [eax + m_es_idx], es
        mov     [eax + m_fs_idx], fs
        mov     [eax + m_gs_idx], gs
        mov     [eax + m_ss_idx], ss

        ;Inicializo eip
        mov     dword [eax + m_eip_idx], sum_routine_2

        ; Inicializo eflags
        mov     dword [eax + m_eflags_idx], 0x200       ; Por lo menos le pongo el bit 9 (IF) a 1 para que interrumpa el
                                                        ; timer.
        ; Inicializo la pila
        mov     dword [eax + m_esp_idx], __TASK2_STACK_END 


    ; Tarea 3
        mov     eax, m_tss_3

        ; Inicializo CR3
        mov     dword [eax + m_CR3_idx], task3_page_directory

        ; Inicializo segmentos
        mov     [eax + m_cs_idx], cs
        mov     [eax + m_ds_idx], ds
        mov     [eax + m_es_idx], es
        mov     [eax + m_fs_idx], fs
        mov     [eax + m_gs_idx], gs
        mov     [eax + m_ss_idx], ss

        ;Inicializo eip
        mov     dword [eax + m_eip_idx], idle_task

        ; Inicializo eflags
        mov     dword [eax + m_eflags_idx], 0x200       ; Por lo menos le pongo el bit 9 (IF) a 1 para que interrumpa el
                                                        ; timer.
        ; Inicializo la pila
        mov     dword [eax + m_esp_idx], __TASK3_STACK_END 

        ret


;______________________________________________________________________________;
;                                Mi TSS                                        ;
;______________________________________________________________________________;
section .scheduler_tables nobits
current_task:
        resd 1                  ; Marcador de tarea en curso    |   0 = Kernel          1 = Task 1
future_task:                    ;                               |         
        resd 1                  ; Marcador de tarea futura      |   3 = Task 3 (idle)   2 = Task 2
m_tss_kernel:
        resd 26
m_tss_1:
        resd 26
m_tss_2:
        resd 26
m_tss_3:
        resd 26