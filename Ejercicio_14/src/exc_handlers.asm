%define BKPT    xchg    bx,bx
%define m_simd  0x68

GLOBAL handler#DE
GLOBAL handler#UD
GLOBAL handler#DF
GLOBAL handler#SS
GLOBAL handler#GP
GLOBAL handler#PF
GLOBAL handler#NM

;Desde init32.asm
EXTERN IDT
EXTERN CS_SEL
EXTERN CS_SEL_ROM

; Desde paging.asm
EXTERN runtime_paging

; Desde screen.asm
EXTERN exc_warning

; Desde scheduler.asm
EXTERN current_task
EXTERN m_simd_task1
EXTERN m_simd_task2

USE32
;______________________________________________________________________________;
;                       Manejadores de interrupciones                          ;
;______________________________________________________________________________;
section .exc_handlers

;Excepcion #DE (Divide error, [0x00])
handler#DE:
        pushad
        call    exc_warning

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     edi, edi
        xor     esi, esi
        xor     ebp, ebp
        mov     dx, 0x00

BKPT

        hlt
        popad
        iret

;Excepcion #UD (Invalid Upcode, [0x06])
handler#UD:
        pushad
        call    exc_warning

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     edi, edi
        xor     esi, esi
        xor     ebp, ebp
        mov     dx, 0x06

BKPT

        hlt
        popad
        iret

;Excepcion #NM (Device not available, [0x07])
handler#NM:
        pushad

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     edi, edi
        xor     esi, esi
        xor     ebp, ebp
        mov     dx, 0x07

        clts

        cmp     dword [current_task], 0x01
        jne     not_t1_SIMD
            fxsave      [m_simd_task2]
            fxrstor     [m_simd_task1]
        not_t1_SIMD:

        cmp     dword [current_task], 0x02
        jne     not_t2_SIMD
            fxsave      [m_simd_task1]
            fxrstor     [m_simd_task2]
        not_t2_SIMD:

        popad
        iret

;Excepcion #DF (Double Fault, [0x08])
handler#DF:
        pushad
        call    exc_warning

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     edi, edi
        xor     esi, esi
        xor     ebp, ebp
        mov     dx, 0x08

BKPT

        hlt
        popad
        iret

;Excepcion #SS (Stack Segment Fault, [0x0C])
handler#SS:
        pushad
        call    exc_warning

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     edi, edi
        xor     esi, esi
        xor     ebp, ebp
        mov     dx, 0x0C

BKPT

        hlt
        popad
        iret

;Excepcion #GP (General Protection, [0x0D])
handler#GP:
        pushad
        call    exc_warning

        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        xor     edi, edi
        xor     esi, esi
        xor     ebp, ebp
        mov     dx, 0x0D

BKPT

        hlt
        popad
        iret

;Excepcion #GP (Page Fault, [0x0E])
handler#PF:
        pushad                          ; Guardo los registros en pila
        call    exc_warning

        xor     eax, eax                ; |
        xor     ebx, ebx                ; |
        xor     ecx, ecx                ; |
        xor     edx, edx                ; | Borro los registros para ver mejor
        xor     edi, edi                ; | en Bochs.
        xor     esi, esi                ; |
        xor     ebp, ebp                ; |
        mov     dx, 0x0E                ; Pongo el numero error para que se vea.
        mov     eax, [current_task]

BKPT

        ; A partir del ejercicio 13 no hay que usar esta funcionalidad
        ;_______________________________________________________________________________________________________________
        mov     eax, CR2                ; Obtengo la dirección que generó el fallo.

        push    eax
        call    runtime_paging
        pop     eax
        ;_______________________________________________________________________________________________________________

        popad                           ; Cargo los registros de nuevo.
        add     esp, 0x04               ; Saco el codigo de error que metió #PF en pila
        iret                            ; Saco EIP, CS y EFLAGS de la pila
