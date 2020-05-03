GLOBAL Funcion_copia

;________________________________________
; Seccion copia
;________________________________________
section .copy

USE32
Funcion_copia:
        mov     ebp, esp        ;Copio la pila en otro registro para no meter la pata
        mov     ecx, [ebp+4]    ;Largo de lo que copio
        mov     edi, [ebp+8]    ;Destino de lo que copio
        mov     esi, [ebp+12]   ;Origen de lo que copio
        rep     cs movsb        ;Repiro la copa hasta copiar todos los bytes

        ret
