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

; Desde task3.asm
EXTERN idle_task

; Desde paging.asm
EXTERN kernel_page_directory
EXTERN task1_page_directory
EXTERN task2_page_directory
EXTERN task3_page_directory

; Desde irq_handlers.asm
EXTERN m_scheduler_int_end

; Desde task1.asm
EXTERN sum_routine

USE32
;______________________________________________________________________________;
;                                 Scheduler                                    ;
;______________________________________________________________________________;
section .scheduler

;________________________________________
; Inicializacion del Scheduler
;________________________________________
scheduler_init:
        ;BKPT

        mov     dword [first_call_t1], 0x01
        mov     dword [first_call_t2], 0x01
        mov     dword [first_call_t3], 0x01

        mov     dword [current_task], 0x00          ; Me voy del Kernel
        mov     dword [future_task], 0x03           ; A la tarea idle

;BKPT
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
        mov     [eax + m_ebx_idx], ebx
        mov     [eax + m_ecx_idx], ecx
        mov     [eax + m_edx_idx], edx
        mov     [eax + m_ebp_idx], ebp
        mov     [eax + m_esi_idx], esi
        mov     [eax + m_edi_idx], edi

        mov     ebx, [esp + 0x08]                       ; Saco de la pila la direccion donde vendra "cs"
        mov     [eax + m_cs_idx], bx                    ; Lo guardo en el contexto
        mov     [eax + m_ds_idx], ds
        mov     [eax + m_es_idx], es
        mov     [eax + m_fs_idx], fs
        mov     [eax + m_gs_idx], gs
        mov     [eax + m_ss_idx], cs
;BKPT
        mov     ebx, [esp + 0x0C]                       ; Saco los eflags de pila
        mov     [eax + m_eflags_idx], ebx               ; Los guardo en el contexto

        mov     ebx, [esp + 0x04]                       ; Saco de la cola la direccion de reinicio de la tarea
        mov     [eax + m_eip_idx], ebx                  ; la guardo en el contexto

        pop     ebx                                     ; Saco el valor de "eax" de pila
        mov     [eax + m_eax_idx], ebx                  ; Lo guardo en el contexto

        pop     ebx                                     ; |
        pop     ebx                                     ; | Balanceo la pila
        pop     ebx                                     ; |

        mov     [eax + m_esp_idx], esp                  ; La guardo en el contexto

    ; Decido que tarea ejecutar ________________________________________________________________________________________

;BKPT
        call    scheduler_logic

    ; Cargo el contexto de la tarea entrante ___________________________________________________________________________
        cmp     dword [future_task], 0x00
        jne     not_kernel_load
            mov     eax, m_tss_kernel                   ; Contexto de kernel
            mov     ebx, 0x00                           ; Aca iria el flag de primera vez llamado pero como es el kernel siempre esta en cero
            jmp     load_context
        not_kernel_load:

        cmp     dword [future_task], 0x01
        jne     not_task1_load
            mov     eax, m_tss_1                        ; Contexto de tarea 1
            mov     ebx, [first_call_t1]                ; Flag de primera inicialización
            cmp     ebx, 0x01                           ; Me fijo si es la primera vez
            jne     load_context                        ; Si no es la primera, salto a cargar el contexto
                mov     dword [first_call_t1], 0x00     ; Si es la primera pongo en cero el flag
                jmp     load_context
        not_task1_load:

        cmp     dword [future_task], 0x02
        jne     not_task2_load
            mov     eax, m_tss_2                        ; Contexto de tarea 2
            mov     ebx, [first_call_t2]                ; Flag de primera inicialización
            cmp     ebx, 0x01                           ; Me fijo si es la primera vez
            jne     load_context                        ; Si no es la primera, salto a cargar el contexto
                mov     dword [first_call_t2], 0x00     ; Si es la primera pongo en cero el flag
                jmp     load_context
        not_task2_load:

        cmp     dword [future_task], 0x03
        jne     not_task3_load
            mov     eax, m_tss_3                        ; Contexto de tarea 3
            mov     ebx, [first_call_t3]                ; Flag de primera inicialización
            cmp     ebx, 0x01                           ; Me fijo si es la primera vez
            jne     load_context                        ; Si no es la primera, salto a cargar el contexto
                mov     dword [first_call_t3], 0x00     ; Si es la primera pongo en cero el flag
                jmp     load_context
        not_task3_load:
    
    
        load_context:
        mov     ecx, [eax + m_ecx_idx]
        mov     edx, [eax + m_edx_idx]
        mov     ebp, [eax + m_ebp_idx]
        mov     esi, [eax + m_esi_idx]
        mov     edi, [eax + m_edi_idx]

        ;mov     ax, [m_tss_3 + m_cs_idx]
        ;mov     cs, ax
        ;mov     ax, [m_tss_3 + m_ds_idx]
        ;mov     ds, ax
        ;mov     ax, [m_tss_3 + m_es_idx]
        ;mov     es, ax
        ;mov     ax, [m_tss_3 + m_fs_idx]
        ;mov     fs, ax
        ;mov     ax, [m_tss_3 + m_gs_idx]
        ;mov     gs, ax
        ;mov     ax, [m_tss_3 + m_ss_idx]
        ;mov     ss, ax

        ; ~~~ PILA ~~~ 
        ;Si es la primera vez tengo que cargar la pila desde el final    
        cmp     ebx, 0x01                           ; Me fijo si es la primera vez
        jne     not_first_call                      ; Si no es me voy al final
            cmp     dword [future_task], 0x01       ; Para la tarea tarea futura
            jne     not_first_1
                mov     esp, __TASK1_STACK_END      ; Cargo el final de la tarea "n"
                jmp     end_stack_load              ; Termino el ciclo.
            not_first_1:

            cmp     dword [future_task], 0x02
            jne     not_first_2
                mov     esp, __TASK2_STACK_END
                jmp     end_stack_load
            not_first_2:

            cmp     dword [future_task], 0x03
            jne     not_first_3
                mov     esp, __TASK3_STACK_END
                jmp     end_stack_load
            not_first_3:

        not_first_call:
            mov     esp, [eax + m_esp_idx]          ; Como no es la primera vez, la pila la tengo que sacar del contexto
        end_stack_load:                             ; Termino la carga de la pila.

BKPT
        ; ~~~ CR3 ~~~
        ; Cargo el directorio correspondiente a la tarea.
        cmp     dword [future_task], 0x01           ; Me fijo si la tarea futura es la 1
        jne     f_t_n_t1                            ; Future Task Not Task1
            mov     ebx, task1_page_directory
            mov     CR3, ebx
        f_t_n_t1:

        cmp     dword [future_task], 0x02           ; Me fijo si la tarea futura es la 2
        jne     f_t_n_t2                            ; Future Task Not Task2
            mov     ebx, task2_page_directory
            mov     CR3, ebx
        f_t_n_t2:

        cmp     dword [future_task], 0x03           ; Me fijo si la tarea futura es la 3
        jne     f_t_n_t3                            ; Future Task Not Task3
            mov     ebx, task3_page_directory
            mov     CR3, ebx
        f_t_n_t3:

;BKPT
        ; **** Logica para calcular eip


        ; ~~~ EFLAGS ~~~
        ; Si es la primera vez, cargo los eflags con el bit de interrupciones a uno. 
        cmp     ebx, 0x01
        jne     not_first_eflags
            mov     dword [eax + m_eflags_idx], 0x200   ; Cargo "ebx" con el bit 9 (IF) a 1.            
        not_first_eflags:                               ; Si no es la primera vez simplemente se carga desde el contexto
            

        ; Cargo en la pila los valores que voy a necesitar en el "iret"
        push    m_scheduler_end_task                ; Cuando termine la tarea quiero que vaya a una rutina de finalizacion
        push    dword [eax + m_eflags_idx]          ; Pusheo "eflags"            |
        push    cs                                  ; Pusheo "cs".               |   Para el "iret".
        push    idle_task
        ;push    dword [eax + m_eip_idx]             ; pusheo "eip".              |


BKPT
        ; Seteo la tarea actual
        mov     ebx, [future_task]
        mov     [current_task], ebx

        ; Una vez que termino de usar los registros, los completo con los valores del contexto nuevo.
        mov     ebx, [eax + m_ebx_idx]              ; Cargo el ebx nuevo
        mov     eax, [eax + m_eax_idx]              ; Cargo el eax nuevo
        

        jmp     m_scheduler_int_end                  ; Vuelvo a irq_handlers.asm
        ;iret
        



;________________________________________
; Logica del Scheduler
;________________________________________
scheduler_logic:


        ;BKPT

        ; Decido que tarea es la que se ejecuta
        mov     dword [current_task], 0x00          ; Me voy del Kernel
        mov     dword [future_task], 0x03           ; A la tarea idle


        ret
        
            


       

; Reemplaza al call tarea_1 desde el scheduler
        ; mov       esp, pila_tarea_1
        ; push      fin_tarea
        ; jmp       tarea_1

        ; tarea_1:
        ;   mov     eax, 0x01
        ;   ret

        ;fin_tarea:

;________________________________________
; Rutina de finalizacion de tarea
;________________________________________
m_scheduler_end_task:
        push    eax                                 ; Pusheo "eax" para usarlo sin problemas
BKPT
    ; Debo resetear el "eip" al principio de la tarea si es que no termino por el tick del scheduler
    ; sino por haber llegado a ret.
        cmp     dword [current_task], 0x01          ; Para la tarea tarea en ejecucion.
        jne     not_reset_eip_1
            mov     eax, m_tss_1
            mov     dword [eax + m_eip_idx], sum_routine    ; Cargo el final de la tarea "n"
            jmp     eip_reset_end                           ; Termino el ciclo.
        not_reset_eip_1:

        cmp     dword [current_task], 0x02
        jne     not_reset_eip_2
            mov     esp, __TASK2_STACK_END
            jmp     eip_reset_end
        not_reset_eip_2:

        cmp     dword [current_task], 0x03
        jne     not_reset_eip_3
            mov     esp, __TASK3_STACK_END
            jmp     eip_reset_end
        not_reset_eip_3:

        eip_reset_end:
        pop     eax                                 ; Recupero "eax" de la pila.
        jmp     m_scheduler

;______________________________________________________________________________;
;                                Mi TSS                                        ;
;______________________________________________________________________________;
section .scheduler_tables nobits
current_task:
        resd 1                  ; Marcador de tarea en curso    |   0 = Kernel
future_task:                    ;                               |   1 = Task 1      2 = Task 2
        resd 1                  ; Marcador de tarea futura      |   3 = Task 3 (idle)
first_call_t1:
        resd 1
first_call_t2:
        resd 1
first_call_t3:
        resd 1
m_tss_kernel:
        resd 26
m_tss_1:
        resd 26
m_tss_2:
        resd 26
m_tss_3:
        resd 26

   

