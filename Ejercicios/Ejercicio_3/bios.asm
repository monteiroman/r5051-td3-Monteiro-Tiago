;Ejercicio 3.
;INICIALIZACIÓN BÁSICA UTILIZANDO SOLO ENSAMBLADOR CON ACCESO A 4GB
;Activar el mecanismo conocido como A20 GATE para acceder al mapa completo de memoria
;del procesador en modo real.
;Adicionalmente agregar el código necesario a fin de que el programa pueda
;   a. Copiarse a sí mismo en la dirección 0x00000000 y ejecutarse desde dicha ubicación
;   b. Copiarse a 0x00300000 y finalizar estableciendo al procesador en estado halted en
;       forma permanente
;   c. Establecer la pila en 0x1FFFA000
;
;Compilar:  nasm bios.asm -o bios.bin -l bios.lst
;Ejecutar:  bochs -qf bochs.cfg

DESTINO1     EQU 0X00000000
DESTINO2     EQU 0X00300000

        bits 16                 ;El codigo que continúa va en segmento de código
                                ; de 16 BITS

Inicio:
        jmp Modo_protegido      ;Aca empieza mi codigo pero primero tengo que
                                ;hacer las tablas

        align 8                 ;Optimización para leer la GDT más rápido (PREGUNTAR)

GDT:
        dq 0                    ;Descriptor nulo. Simepre tiene que estar.

CS_SEL  equ $-GDT               ;Defino el selector de Código
                                ; Base = 00000000, límite = FFFFFFFF.
                                ; Granularidad = 1, límite = FFFFF.
        dw 0xffff               ;Límite 15-0
        dw 0                    ;Base 15-0
        db 0                    ;Base 23-16
        db 10011010b            ;Derechos de acceso.
                                ;Bit 7 = 1 (Presente), Bits 6-5 = 0 (DPL),
                                ;Bit 4 = 1 (Todavia no vimos por qué),
                                ;Bit 3 = 1 (Código), Bit 2 = 0 (no conforming),
                                ;Bit 1 = 1 (lectura), Bit 0 = 0 (Accedido).
        db 0xcf                 ;G = 1, D = 1, límite 19-16
        db 0                    ;Base 31-24

DS_SEL  equ $-GDT               ;Defino el selector de Datos flat.
                                ; Base 000000000, límite FFFFFFFF,
                                ; Granularidad = 1, límite = FFFFF.
        dw 0xffff               ;Límite 15-0
        dw 0                    ;Base 15-0
        db 0                    ;Base 23-16
        db 10010010b            ;Derechos de acceso.
                                ;Bit 7 = 1 (Presente), Bits 6-5 = 0 (DPL),
                                ;Bit 4 = 1 (Todavia no vimos por qué),
                                ;Bit 3 = 0 (Datos), Bit 2 = 0 (dirección de
                                ;expansión) normal), Bit 1 = 1 (R/W),
                                ;Bit 0 = 0 (Accedido).
        db 0xcf                 ;G = 1, D = 1, límite 19-16
        db 0                    ;Base 31-24

tam_GDT equ $-GDT               ;Tamaño de la GDT.

imagen_gdtr:
        dw tam_GDT - 1          ;Limite GDT (16 bits).
        dd 0xffff0000 + GDT     ;Base GDT (32 bits).

Modo_protegido:

        cli                     ;Desabilitar interrupcionees.
        o32 lgdt [cs:imagen_gdtr]   ;Cargo registro GDTR.
                                    ;El prefijo 0x66 que agrega el o32 permite
                                    ;usar los 4 bytes de la base. Sin o32 se
                                    ;usan tres.
        mov eax, cr0            ;Paso a modo protegido.
        or  eax, 1              ;Prendo el bit 1
        xchg bx, bx
        mov cr0, eax
        xchg bx, bx

        jmp dword CS_SEL:(0xFFFF0000+Inicio_32bits)     ;Cambio el CS al selector
                                                            ;de modo protegido.

        BITS 32                 ;El codigo que continúa va en segmento de código
                                ; de 32 BITS

Inicio_32bits:

        mov ax, DS_SEL          ;Cargo DS con el selector que apunta al
        mov ds, ax              ;descriptor de segmento de datos flat.
        mov es,ax
        ;xchg bx, bx
        ;hlt

        mov     ax,DS_SEL
        mov     ss,ax           ;Inicio el selector de pila
        mov     esp,0x1FFFA000  ;Cargo el registro de pila y le doy
                                    ;direccion de inicio

        ;En los registros: ax (destino), bx (largo) y cx (inicio)

        mov     eax,DESTINO1    ;0x00000000
        mov     ebx,LARGO       ;Calculo el largo al final
        mov     ecx,0xFFFF0000+Funcion_copia       ;Inicio de la copia. Copio el
                                                        ;pedazo de codigo que me
                                                        ;interesa.

        xchg    bx,bx           ;Magic breakpoint
        call Funcion_copia

        mov     eax,DESTINO2    ;0x00300000
        mov     ebx,LARGO       ;Como se copia a si misma calculo el largo al
                                    ;final
        mov     ecx,DESTINO1    ;En este caso se copia la funcion a si misma

        call ecx                ;No se porque no me funciona con "call dword DESTINO1"

        xchg    bx,bx           ;Magic breakpoint
        hlt                     ;pongo en halt el procesador


Funcion_copia:
        mov     edi,eax         ;Pongo "edi" en cero para completar la dirección
                                    ;de destino
        mov     esi,ecx         ;Cargo el inicio en "esi" (para movsb)
        mov     ecx,ebx         ;Pongo el largo en "ecx" (para rep)
        rep     cs movsb        ;Muevo los bytes
        xchg    bx,bx           ;Magic breakpoint

        ret                     ;Retorno a donde llame.

        LARGO EQU ($ - Funcion_copia)   ;Calculo el largo en base al programa
                                            ;actual en el futuro va a ser un
                                            ;parametro de la funcion.


        times 0xFFF0 - ($ - Inicio)  db 0   ;Primer relleno.

        bits 16                ;El código a continuación va en
                               ;segmento de código de 16 bits.

reset:                        ;Dirección de arranque del procesador.
       jmp Inicio - $$        ;Saltar al principio de la ROM.

       times 0x10 - ($ -reset) db 0        ;Segundo relleno.
