%define BKPT    xchg    bx,bx

GLOBAL handler#DE
GLOBAL handler#UD
GLOBAL handler#DF
GLOBAL handler#GP
GLOBAL handler#PF

;Desde init32.asm
EXTERN IDT
EXTERN CS_SEL
EXTERN CS_SEL_ROM

; Desde paging.asm
EXTERN runtime_paging

USE32

;______________________________________________________________________________;
;                       Manejadores de interrupciones                          ;
;______________________________________________________________________________;
section .exc_handlers

;Excepcion #DE (Divide error, [0x00])
handler#DE:
        pushad
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

;Excepcion #DF (Double Fault, [0x08])
handler#DF:
        pushad
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

;Excepcion #GP (General Protection, [0x0D])
handler#GP:
        pushad
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
        xor     eax, eax                ; \
        xor     ebx, ebx                ; |
        xor     ecx, ecx                ; |
        xor     edx, edx                ; | Borro los registros para ver mejor
        xor     edi, edi                ; | en Bochs.
        xor     esi, esi                ; |
        xor     ebp, ebp                ; /
        mov     dx, 0x0E                ; Pongo el numero error para que se vea.

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
