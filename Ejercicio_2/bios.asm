;Ejercicio 2
;Escribir un programa que se ejecute en una ROM de 64kB y permita copiarse a sí mismo en
;cualquier zona de memoria. A tal fin se deberá implementar la función
;void *td3_memcopy(void *destino, const void *origen, unsigned int num_bytes);
;Para validar el correcto funcionamiento del programa, el mismo deberá copiarse en las
;direcciones indicadas a continuación y mediante Bochs verificar que la memoria se haya
;escrito correctamente.
;i.     0x00000
;ii.    0x60000
;
;Compilar:  nasm bios.asm -o bios.bin -l bios.lst
;Ejecutar:  bochs -qf bochs.cfg


DESTINO1     EQU 0X0000
DESTINO2     EQU 0X6000
USE16

Inicio:
    mov     ax,0
    mov     ds,ax               ;Inicio el selector de datos
    mov     ss,ax               ;Inicio el selector de pila
    mov     sp,0x8000           ;Cargo el registro de pila y le doy direccion de inicio

    ;Llegan los parametros por los registros ax (destino) y bx (largo)
    mov     ax,DESTINO1
    mov     bx,LARGO            ;Como se copia a si misma calculo el largo al final
    mov     cx,Funcion_copia    ;En este caso se copia la funcion a si misma

    call Funcion_copia

    mov     ax,DESTINO2
    mov     bx,LARGO            ;Como se copia a si misma calculo el largo al final
    mov     cx,Funcion_copia    ;En este caso se copia la funcion a si misma

    call Funcion_copia

    xchg    bx,bx               ;Magic breakpoint
    hlt                         ;pongo en halt el procesador

Funcion_copia:
    mov     es,ax               ;Cargo el destino en "es" (para movsb)
    mov     si,cx               ;Cargo el inicio en "si" (para movsb)
    mov     di,0                ;Pongo "di" en cero para completar la dirección de destino
    mov     cx,bx               ;Pongo el largo en "cx" (para rep)
    rep     cs movsb            ;Muevo los bytes
    xchg    bx,bx               ;Magic breakpoint

    ret                         ;Retorno a donde llame.

LARGO EQU ($ - Funcion_copia)   ;Calculo el largo en base al programa actual
                                ;en el futuro va a ser un parametro de la
                                ;funcion.
times 0xFFF0-($-Inicio) db 0

Entrada:
    jmp Inicio - $$
    times   16-($-Entrada) db 0 ;Relleno la ROM
