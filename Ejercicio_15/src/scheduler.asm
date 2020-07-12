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
%define m_at_syscall    0x68

GLOBAL scheduler_init
GLOBAL current_task
GLOBAL future_task
GLOBAL m_scheduler
GLOBAL m_simd_task1
GLOBAL m_simd_task2
GLOBAL m_tss_length
GLOBAL m_tss_kernel
GLOBAL at_syscall_t1
GLOBAL at_syscall_t2
GLOBAL at_syscall_t3

; Desde keyboard.asm
EXTERN enter_key_flag                         
EXTERN enter_key_flag_2

; Desde timer.asm
EXTERN timer_flag                             
EXTERN timer_flag_2

; Desde biosLS.lds
EXTERN __TASK1_STACK_END
EXTERN __TASK2_STACK_END
EXTERN __TASK3_STACK_END
EXTERN __TASK1_KERNEL_STACK_END
EXTERN __TASK2_KERNEL_STACK_END
EXTERN __TASK3_KERNEL_STACK_END

; Desde paging.asm
EXTERN kernel_page_directory
EXTERN task1_page_directory
EXTERN task2_page_directory
EXTERN task3_page_directory

; Desde irq_handlers.asm
EXTERN m_scheduler_int_end

; Desde task1.asm
EXTERN sum_routine
EXTERN task1_end_flag

; Desde task2.asm
EXTERN sum_routine_2
EXTERN task2_end_flag

; Desde task3.asm
EXTERN idle_task

; Desde screen.asm
EXTERN refresh_screen

; Desde init.asm
EXTERN TSS_SEL
EXTERN CS_SEL_USER
EXTERN DS_SEL_USER
EXTERN CS_SEL_KERNEL
EXTERN DS_SEL_KERNEL

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

        mov     ax, TSS_SEL
        ltr     ax                                  ; Cargo el registro de tarea.

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

    ; Guardo el contexto de la tarea saliente __________________________________
        jmp    save_old_context                     ; En los lugares donde uso jmp en vez de call 
        save_old_context_done:                      ;   busco no desorganizar la pila.

    ; Muestro en pantalla ______________________________________________________
        call    refresh_screen

    ; Decido que tarea ejecutar ________________________________________________
        call    scheduler_logic

    ; Cargo el contexto de la tarea entrante ___________________________________

        jmp     load_new_context
        load_new_context_done:

        jmp     m_scheduler_int_end                 ; Vuelvo al manejador de 
                                                    ;   interrupcion (ver 
                                                    ;   irq_handlers.asm).

;______________________________________________________________________________;
;                        Funciones del Scheduler                               ;
;______________________________________________________________________________;

;________________________________________
; Guardado del Contexto
;________________________________________
save_old_context:

        push    eax                                     ; Guardo eax en la pila para usarlo de

    ; Registros de SIMD_________________________________________________________
        mov     eax, cr0                                ; Miro si se cambio el bit CR0.3 (TS). Si esta en cero es porque 
        and     eax, 0x08                               ;   se uso SIMD. 
        cmp     eax, 0x08                               ; Comparo si TS esta en 1.
        jne     no_simd
            cmp     dword [current_task], 0x01          ; Si la tarea actual es la 1.
            jne     not_t1_SIMD
                fxsave      [m_simd_task1]              ; Guardo los registros SIMD de la tarea 1.
            not_t1_SIMD:

            cmp     dword [current_task], 0x02          ; Si la tarea actual es la 2.
            jne     not_t2_SIMD
                fxsave      [m_simd_task2]              ; Guardo los registros SIMD de la tarea 2.
            not_t2_SIMD:
        no_simd:

        mov     eax, cr0
        or      eax, 0x08		                        ; Pongo en 1 el bit 3 (Task Switched) para que entre en #NM.
        mov     cr0, eax

    ; Identifico la tarea_______________________________________________________
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

    ; Guardo el contexto________________________________________________________
        save_context:                                   
        ; Guardo registros (menos eax que lo guardo al final).
        mov     [eax + m_ebx_idx], ebx
        mov     [eax + m_ecx_idx], ecx
        mov     [eax + m_edx_idx], edx
        mov     [eax + m_ebp_idx], ebp
        mov     [eax + m_esi_idx], esi
        mov     [eax + m_edi_idx], edi

        ; Ya puedo usar los registros, los uso para guardar los selectores de segmentos.
        mov     [eax + m_ds_idx], ds
        mov     [eax + m_es_idx], es
        mov     [eax + m_fs_idx], fs
        mov     [eax + m_gs_idx], gs
        mov     [eax + m_ss_idx], ss

    ; Desarmo la pila___________________________________________________________
        ; Guardo cs
        mov     ebx, [esp + 0x08]                       ; Saco de la pila la direccion donde vendra "cs"
        mov     [eax + m_cs_idx], bx                    ; Lo guardo en el contexto

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

        mov     [eax + m_esp_idx], esp

        cmp     dword [eax + m_at_syscall], 0x01
        je      save_old_context_done                   ; -Si vengo de una syscall estoy hecho.
        ; Guardo la pila.
            pop     ebx                                 ; -Si no vengo de una syscall, saco los  
            mov     [eax + m_esp_idx], ebx              ;   valores de ss y de esp de la tarea que
        ; Guardo ss.                                    ;   aun se encuentran en la pila y los guardo
            pop     ebx                                 ;   en el contexto.
            mov     [eax + m_ss_idx], ebx               
                                                        
            jmp     save_old_context_done               ; Punto de retorno.


;________________________________________
; Carga de contexto nuevo.
;________________________________________
load_new_context:

    ; Identifico la tarea_______________________________________________________
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
    
    ; Cargo el contexto_________________________________________________________
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

        ; Cambio CR3
        mov     ebx, [eax + m_CR3_idx]
        mov     CR3, ebx

    ; Armo la pila______________________________________________________________
        cmp     dword [eax + m_at_syscall], 0x01        
        jne     not_at_syscall                          
            mov     ebx, [eax + m_esp_idx]              ; Si vengo desde una syscall, cargo la direccion de pila que 
            mov     esp, ebx                            ;   corresponde. Esta direccion aun tiene los valores de retorno 
            jmp     at_syscall                          ;   de la tarea que llamo a la syscall.
        not_at_syscall:
        
    ; Si no estaba en una syscall tengo que cargar mas valores a la pila ya que hay cambio de privilegio.
        ; Cargo la pila de kernel de la tarea corespondiente
        mov     ebx, [eax + m_esp0_idx]
        mov     esp, ebx

        ; Cargo ss.
        xor     ebx, ebx
        mov     ebx, [eax + m_ss_idx]
        push    ebx  

        ; Cargo dirección de pila.    
        mov     ebx, [eax + m_esp_idx]
        push    ebx  

    ; Si estaba en una syscall tengo que cargar menos valores a la pila ya que no hay cambio de privilegio.
        at_syscall:    
                                                        ;               ________________
        mov     ebx, [eax + m_eflags_idx]               ; Pusheo "eflags"               |
        push    ebx                                     ;                               |
        push    dword [eax + m_cs_idx]                  ; Pusheo "cs".                  |   
                                                        ;                               |
        cmp     dword [future_task], 0x03               ; -Si es la tarea 3 que vuelva  | 
        je      prev_return_point                       ;   al punto de donde salio.    |
            cmp     dword [future_task], 0x02           ; _                             |
            jne     not_task2_return                    ;  |                            |
            cmp     dword [task2_end_flag], 0x01        ;  | Si la tarea futura es la   |   Preparo la pila para 
            jne     prev_return_point                   ;  | tarea 2 y llego hasta el   |   el "iret".
                mov     ebx, sum_routine_2              ;  | final se resetea.          |
                jmp     reset_return_point              ; _|                            |
            not_task2_return:                           ;                               |
                                                        ;                               |
            cmp     dword [future_task], 0x01           ; _                             |
            jne     prev_return_point                   ;  |                            |
            cmp     dword [task1_end_flag], 0x01        ;  | Si la tarea futura es la   |
            jne     prev_return_point                   ;  | tarea 1 y llego hasta el   |
                mov     ebx, sum_routine                ;  | final se resetea.          |
                jmp     reset_return_point              ; _|                            |
        prev_return_point:                              ;                               |
        mov     ebx, [eax + m_eip_idx]                  ;                               |
        reset_return_point:                             ;                               |
        push    ebx                                     ; pusheo "eip".                 |
                                                        ;               ________________|
    ; Finalizo el armado del contexto___________________________________________
        ; Seteo la tarea actual
        mov     ebx, [future_task]
        mov     [current_task], ebx

        ; Una vez que termino de usar los registros, los completo con los valores del contexto nuevo.
        mov     ebx, [eax + m_ebx_idx]                  ; Cargo el ebx nuevo.
        mov     eax, [eax + m_eax_idx]                  ; Cargo el eax nuevo.

        jmp     load_new_context_done                   ; Punto de retorno.


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
; --->  
;BKPT
        jmp     default_task
; --->  




        ; Desde la Tarea 3 salto a la Tarea 1 o a la Tarea 2 según corresponda.
        cmp     dword [current_task], 0x03
        jne     not_idle_task_round
            ; Salto a Tarea 1
            cmp     dword [timer_flag], 0x01
            jne     not_3_to_1
                mov     dword [future_task], 0x01
                mov     dword [timer_flag], 0x00
                ret
            not_3_to_1:
            ; Salto a Tarea 2
            cmp     dword [timer_flag_2], 0x01
            jne     not_3_to_2
                mov     dword [future_task], 0x02
                mov     dword [timer_flag_2], 0x00
                ret
            not_3_to_2:
        not_idle_task_round:
        
        ; Desde la Tarea 1 salto a la Tarea 2 o a la Tarea 3 según corresponda.
        cmp     dword [current_task], 0x01
        jne     not_task1_round
            ; Salto a Tarea 2
            cmp     dword [timer_flag_2], 0x01
            jne     not_1_to_2
                mov     dword [future_task], 0x02
                mov     dword [timer_flag_2], 0x00
                ret
            not_1_to_2:
            ; Salto a Tarea 3
            mov     dword [future_task], 0x03       
            ret
        not_task1_round:
        
        ; Desde la Tarea 2 salto a la Tarea 1 o a la Tarea 3 según corresponda.
        cmp     dword [current_task], 0x02
        jne     not_task2_round
            ; Salto a Tarea 1
            cmp     dword [timer_flag], 0x01
            jne     not_2_to_1
                mov     dword [future_task], 0x01
                mov     dword [timer_flag], 0x00
                ret
            not_2_to_1:
            ; Salto a Tarea 3
            mov     dword [future_task], 0x03       
            ret
        not_task2_round:

        default_task:
        mov     dword [future_task], 0x03
        ret


;________________________________________
; Rutina de Inicializacion de contextos
;________________________________________
contexts_init:

    ; Kernel. Aqui es donde estaran las direcciones lineales de las pilas de 
    ;           PL=0 y PL=3 que no cambian entre tareas.
        mov     eax, m_tss_kernel

        ; Inicializacion de la pila de PL=0
        mov     dword [eax + m_esp0_idx], __TASK3_KERNEL_STACK_END
        mov     word [eax + m_ss0_idx], DS_SEL_KERNEL


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
        mov     dword [eax + m_eflags_idx], 0x202       ; Por lo menos le pongo el bit 9 (IF) a 1 para que interrumpa el
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
        mov     dword [eax + m_eflags_idx], 0x202       ; Por lo menos le pongo el bit 9 (IF) a 1 para que interrumpa el
                                                        ; timer.
        ; Inicializo la pila
        mov     dword [eax + m_esp_idx], __TASK2_STACK_END


    ; Tarea 3
        mov     eax, m_tss_3

        ; Inicializo CR3
        mov     dword [eax + m_CR3_idx], task3_page_directory

        ; Inicializo segmentos
        mov     cx, DS_SEL_USER
        mov     bx, CS_SEL_USER
        mov     [eax + m_cs_idx], bx
        mov     [eax + m_ds_idx], cx
        mov     [eax + m_es_idx], cx
        mov     [eax + m_fs_idx], cx
        mov     [eax + m_gs_idx], cx
        mov     [eax + m_ss_idx], cx

        ;Inicializo eip
        mov     dword [eax + m_eip_idx], idle_task

        ; Inicializo eflags
        mov     dword [eax + m_eflags_idx], 0x202       ; Por lo menos le pongo el bit 9 (IF) a 1 para que interrumpa el
                                                        ; timer.
        ; Inicializo la pila
        mov     dword [eax + m_esp_idx], __TASK3_STACK_END

        ; Inicializo la pila de PL=0
        mov     dword [eax + m_esp0_idx], __TASK3_KERNEL_STACK_END

        ; Inicializo el flag de syscall activa
        mov     dword [eax + m_at_syscall], 0x00
 
        ret


;______________________________________________________________________________;
;                                Datos                                         ;
;______________________________________________________________________________;
section .scheduler_tables nobits
;________________________________________
; Flags de Tareas
;________________________________________
current_task:
        resd 1                  ; Marcador de tarea en curso    |   0 = Kernel          1 = Task 1
future_task:                    ;                               |         
        resd 1                  ; Marcador de tarea futura      |   3 = Task 3 (idle)   2 = Task 2


;________________________________________
; Mi TSS
;________________________________________
m_tss_kernel:
        resd 26                         ; TSS identica a la de intel.
    m_tss_length equ $-m_tss_kernel     ; Largo de la tss que voy a usar en tr.

m_tss_1:
        resd 26                 ; TSS identica a la de intel.
at_syscall_t1:                     
        resd 1                  ; Flag para saber si se produjo el salto al scheduler durante la syscall en Tarea 1.

m_tss_2:
        resd 26                 ; TSS identica a la de intel.
at_syscall_t2:                     
        resd 1                  ; Flag para saber si se produjo el salto al scheduler durante la syscall en Tarea 2.


m_tss_3:
        resd 26                 ; TSS identica a la de intel.
at_syscall_t3:                     
        resd 1                  ; Flag para saber si se produjo el salto al scheduler durante la syscallen Tarea 3.


ALIGN 512                       ; Alineo los espacios de memoria para SIMD
m_simd_task1:
        resb 512
m_simd_task2:
        resb 512
