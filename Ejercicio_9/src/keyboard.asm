
%define BKPT    xchg    bx,bx

%define Keyb_Ctrl_Stat_Reg      0x64
%define Keyb_Out_Buffer_Reg     0x60

%define number_bytes   8

GLOBAL keyboard_fill_lookup_table
GLOBAL keyboard_routine

GLOBAL loop_buffer

GLOBAL timer_count


;Desde el linkerscript
EXTERN __SAVED_DIGITS_START
EXTERN __SAVED_DIGITS_END
EXTERN __ROUND_BUFFER_START
EXTERN __ROUND_BUFFER_END

;Desde handlers.asm
EXTERN IDT_handler_cleaner

;Desde timer.asm.
EXTERN timer_count

USE32
;______________________________________________________________________________;
;                       Inicialización para el teclado                         ;
;______________________________________________________________________________;

;________________________________________
; Tabla para guardar los digitos
;________________________________________
;Aca voy a guardar los digitos ingresados. Se usa nobits para decirle al linker
;que esta sección va a existir pero que no le carge nada.
section .saved_digits_table nobits
    timer_count:
        resb 8
    saved_digits_table_index:
        resb 8                        ; Reservo dos bytes para indice
    saved_digits_table:
        resb 64*1024                  ; Reservo Los 64k de la tabla.
        saved_digits_table_end:

;________________________________________
; Buffer circular del teclado
;________________________________________
;En este buffer se van a ir guardando los numeros hasta que se presione enter,
;luego los copio a la tabla de guardados.
section .round_buffer nobits
    round_buffer_index:
        resb 8
    dummy_byte:                         ; PAra que me quede ordenada la tabla cuando la miro en Bochs.
        resb 8
    round_buffer:
        resb 9                          ; Reservo los bytes del buffer circular.
        round_buffer_end:
        round_buffer_size equ $-round_buffer

 ;________________________________________
 ; Tabla para identificar los digitos
 ; que se presionaron
 ;________________________________________
 ;Reservo el espacio para la tabla de digitos con espacio para añadir mas digitos
 ;en ejercicios posteriores.
section .keyboard_table nobits
table:
        resb 0xA6                   ;La hago pensando en que uso todas las teclas
                                    ;   del teclado.
;Lleno "table" con el codigo de los digitos que voy a necesitar. Esta parte va
;en ROM y se carga en el inicio.

section .keyboard_table_init
keyboard_fill_lookup_table:
        mov     ebp, table          ;Pongo la direccion de la tabla que se encuentra en ram

                    ;Posicion de teclado       Valor
        mov word        [ebp+0x02],             0x1    ;La lleno con cada valor de las teclas que
        mov word        [ebp+0x03],             0x2        ;pueden ser presionadas en este ej.
        mov word        [ebp+0x04],             0x3
        mov word        [ebp+0x05],             0x4
        mov word        [ebp+0x06],             0x5
        mov word        [ebp+0x07],             0x6
        mov word        [ebp+0x08],             0x7
        mov word        [ebp+0x09],             0x8
        mov word        [ebp+0x0A],             0x9
        mov word        [ebp+0x0B],             0x0
        mov word        [ebp+0x21],             0xF
        mov word        [ebp+0x1C],             0xE     ;ENTER no me interesa el valor en la tabla, no se guarda

        ;mov word        [ebp+0x15],             0x00    ;Y
        ;mov word        [ebp+0x16],             0x06    ;U
        ;mov word        [ebp+0x17],             0x08    ;I
        ;mov word        [ebp+0x18],             0x0D    ;O

        ret


;______________________________________________________________________________;
;                           Rutina del teclado                                 ;
;______________________________________________________________________________;
section .keyboard
keyboard_routine:
        pushad                       ;Pusheo los registros a pila.

    buffer_check:
        xor     eax,eax
        in      al, Keyb_Ctrl_Stat_Reg      ;Miro el puerto 0x64 "Keyboard Controller Status Register".
        and     al, 0x01                    ;Obtengo el bit 0 "Output buffer status" haciendo una AND.
        cmp     al, 0x01                    ;Si "Output buffer status" vale 1 el buffer tiene informacion que se puede leer.
        jnz     exit                        ;Si está vacío salgo.

        ;CMP hace la resta de las dos fuentes que se le pasan para saber si son
        ;iguales. Cuando lo son, la resta da cero -> se pone en 1 el flag de cero
        ;de EIP. En el caso anterior, si no son iguales JNZ salta a buffer_check
        ;de nuevo para seguir chequeando.

        in      al, Keyb_Out_Buffer_Reg     ;Miro el puerto 0x60 "Keyboard Output Buffer Register".
        mov     bl, al                      ;Copio lo leído en otro registro por prolijidad.
        and     bl, 0x80                    ;Obtengo el bit 7 "BRK" haciendo una AND.
        cmp     bl, 0x80                    ;0 -> Make (se presiono la tecla), 1 -> Break (se libero la tecla).
        jz      exit                        ;Se desea detectar cuando la tecla se suelta. Si fue presionada vuelvo a buffer_check.

        ;Si presiono F paro el programa para ver el valor de la cuenta de timer
        cmp     al, 0x21
        jnz continue
            mov     ax, [timer_count]
            BKPT
            continue:

        ;Si la tecla presionada y liberada es ENTER; guardo el buffer.
        cmp     al, 0x1C
        jz      save_buffer

        ;Chequeo si es mayor a la tecla "0". Si lo es salto a chequear el buffer
        cmp     al, 0x0B
        jg      exit

        ;Chequeo si es menor a la tecla "1" (solo "ESC"). Si lo es salto de
        ;nuevo a chequear el buffer del teclado.
        cmp     al, 0x02
        jl      exit

        jmp     save_number_in_buffer        ;es un numero -> lo guardo


;________________________________________
; Funcion de guardado de numeros
; en el buffer.
;________________________________________
    save_number_in_buffer:
        ;En "al" ya tenia el valor que presionaron, si le sumo ebp obtengo,
        ;desde la lookup table, el valor de la tecla que apretaron.
        mov     ebp, table           ;Busco la direccion de la tabla de inspeccion.
        xor     ecx,ecx
        mov     cl, [ebp+eax]

        ;Inicio los punteros del buffer de guardado de los caracteres.
        xor     ebx, ebx
        mov     bl, [round_buffer_index]    ; Valor del indice
        mov     edx, round_buffer_end       ; Final del buffer
        mov     edi, round_buffer           ; Inicio del buffer

        ;Chequeo si estoy por sobrepasar el buffer
        shr     ebx, 1                      ; Divido el indice por dos (este indice indica nibles no bytes)
        add     edi, ebx                    ; Sumo ebx y edi para tener la posicion exacta en el buffer.
        cmp     edi, edx                    ; Comparo con el final del buffer.
        jnz     round_buffer_not_overflow   ; Si hizo overflow, reseteo el indice.
          mov     ebx,0                     ;    que venia manejando en ebx.
          mov     [round_buffer_index], bl  ; Guardo el indice reseteado.

        ;Una vez solucionada la parte de overflow.
        round_buffer_not_overflow:
        xor     ebx, ebx                        ; Limpio registros.
        xor     eax, eax
        xor     edx, edx
        mov     ebx, [round_buffer_index]       ; Vuelvo a cargar el indice. (Indica nibles).
        mov     eax, ebx
        mov     edx, ebx
        shr     edx, 1                          ; Divido por dos el indice. (Indica bytes).
        and     eax, 0x01
        cmp     eax, 0x01                       ; Me fijo si el nible es par o impar.
        jz      not_even_index
            shl     ecx, 4                      ; Muevo el valor de la tecla para que quede en la parte alta.
            mov     al, [round_buffer + edx]    ; Traigo lo que tengo en esa posicion
            and     al, 0x0F                    ; Le borro la parte alta
            or      cl, al                      ; Sumo el valor nuevo con lo que ya habia
            mov     [round_buffer + edx], cl    ; Guardo el valor.
            jmp     saving_end                  ; Termino.
        not_even_index:
            mov     al, [round_buffer + edx]    ; Traigo lo que tengo en esa posicion
            and     al, 0xF0                    ; Le borro la parte baja
            or      cl, al                      ; Sumo el valor nuevo con lo que ya habia
            mov     [round_buffer + edx], cl    ; Cargo el valor en el buffer.
        saving_end:
        inc     bx
        mov     [round_buffer_index], bl        ;guardo el indice

        jmp     exit


;________________________________________
; Funcion de guardado de numeros
; del buffer en la tabla.
;________________________________________
    save_buffer:
        ;Inicio los punteros de las tablas de guardado de los caracteres.
        mov     edi, [saved_digits_table_index]
        mov     edx, saved_digits_table_end
        ;Chequeo si el inicio y el final son iguales. Si lo son estoy por entrar
        ;en overflow en la lista de digitos guardados. Si no lo
        ;son, puedo seguir guardando.
        cmp     [saved_digits_table + edi], edx
        jnz     not_overflow
            mov     edi,0
            mov     [saved_digits_table_index], edi
        not_overflow:
        mov     ebp, round_buffer
        mov     esi, [round_buffer_index]   ; Indice en nibles.
        mov     edx, esi
        shr     edx, 1                      ; Indice en bytes.
        mov     eax, esi
        and     eax, 0x01
        cmp     eax, 0x01                   ; Me fijo si la cantidad de nibles es par
        jz      not_even_nibles
        ; Si la cantidad de nibles es par puedo levanta byte a byte desde el buffer
        ; circular. RECORRO EN DIRECCION INVERSA AL LLENADO.
        ;
        ; Ejemplo:
        ; Buffer circular:
        ;    __________________________________________________________________________________________________________
        ;   |          ||          ||         ||          ||           ||         ||         ||           ||           |
        ;   | n14  n15 ||  X    X  || n0   n1 || n2   n3  ||  n4   n5  || n6   n7 || n8   n9 || n10   n11 || n12   n13 |
        ;   |____·_____||____·_____||____·____||_____·____||_____·_____||____·____||____·____||_____·_____||_____·_____|
        ;      Byte 0     Byte 1     Byte 2      Byte 3      Byte 4       Byte 5      Byte 6      Byte 7       Byte 8
        ;
        ;
        ;Posicion de memoria: (Para poder levantarlo en un registro)
        ;    _______________________________________________________________________________________________
        ;   |          ||          ||           ||          ||           ||         ||         ||          |
        ;   | n14  n15 || n12  n13 || n10   n11 || n8   n9  ||  n6   n7  || n4   n5 || n2   n3 || n0    n1 |
        ;   |____·_____||____·_____||_____·_____||_____·____||_____·_____||____·____||____·____||_____·____|
        ;      Byte 0     Byte 1       Byte 2       Byte 3      Byte 4       Byte 5     Byte 6     Byte 7
        ;
        ;
        dec     edx                                     ; Me ubico en el ultimo byte ingresado
        mov     ebx, 0x08                               ; Cantidad de veces que voy a repetir en ciclo (Cantidad de bytes a levantar)
        saving_loop1:
            mov     al, [round_buffer + edx]            ; Saco del buffer.
            mov     [saved_digits_table + edi], al      ; Guardo en la tabla.
            inc     edi                                 ; Incremento el indice de la tabla.
            mov     [saved_digits_table_index], edi     ; Guardo el indice de la tabla en memoria.
            cmp     edx, 0                              ; Comparo si el indice del buffer me da cero.
            jnz      not_underflow
                mov     edx, round_buffer_size          ; Si llegué al principio voy al final del buffer (9 BYTES).
            not_underflow:
            dec     edx                                 ; Decremento el indice con el que saco del buffer.
            dec     ebx                                 ; Decremento la cantidad de veces.
            cmp     ebx, 0x00                           ; Chequeo si lo hice 8 veces (Cantidad de bytes a levantar).
            jz      clean_buffer                        ; Me voy.
        jmp     saving_loop1

        ; Cuando la cantidad de nibles es impar el problema que se presenta es que quedan dos nibles
        ; cruzados. Estos los tengo que tratar especialmente.
        ;
        ; Ejemplo:
        ; Buffer circular:
        ;    __________________________________________________________________________________________________________
        ;   |          ||         ||         ||          ||           ||         ||         ||           ||           |
        ;   | n13  n14 || n15  X  || X    n0 || n1   n2  ||  n3   n4  || n5   n6 || n7   n8 || n9    n10 || n11   n12 |
        ;   |____·_____||____·____||____·____||_____·____||_____·_____||____·____||____·____||_____·_____||_____·_____|
        ;      Byte 0     Byte 1     Byte 2      Byte 3      Byte 4       Byte 5      Byte 6      Byte 7       Byte 8
        ;
        ;
        ;Posicion de memoria: (Para poder levantarlo en un registro)
        ;    _______________________________________________________________________________________________
        ;   |          ||          ||           ||          ||           ||         ||         ||          |
        ;   | n14  n15 || n12  n13 || n10   n11 || n8   n9  ||  n6   n7  || n4   n5 || n2   n3 || n0    n1 |
        ;   |____·_____||____·_____||_____·_____||_____·____||_____·_____||____·____||____·____||_____·____|
        ;      Byte 0     Byte 1     Byte 2      Byte 3      Byte 4       Byte 5      Byte 6      Byte 7

        not_even_nibles:
        ; Para el primer nible________________
        ;BKPT
        first_nible:
        mov     al, [round_buffer + edx]                ; Saco del buffer.
        shr     al, 4                                   ; Lo muevo a la derecha para convertirlo en parte baja de mi byte
        or     [saved_digits_table + edi], al           ; Guardo en memoria
        cmp     edx, 0x00                               ; Chequeo si me cai del buffer
        jnz     not_underflow2
            mov     edx, round_buffer_size              ; Si me cai vuelvo a cargar el valor de bytes del buffer
        not_underflow2:
        dec     edx                                     ; Decremento el indice del buffer
        ; Para los otros 7 Bytes______________
        mov     ebx, 0x07
        saving_loop2:
        mov     al, [round_buffer + edx]                ; Saco del buffer.
        mov     cl, [round_buffer + edx]                ; Saco del buffer.
        and     al, 0x0F                                ; Me quedo con la parte baja del byte.
        shl     al, 4
        or      [saved_digits_table + edi], al
        inc     edi
        mov     [saved_digits_table_index], edi         ; Guardo el indice de la tabla en memoria.
        and     cl, 0xF0                                ;parte alta del byte
        shr     cl, 4
        or     [saved_digits_table + edi], cl
        cmp     edx, 0x00
        jne      not_underflow3
            mov     edx, round_buffer_size
        not_underflow3:
        dec     edx
        dec     ebx
        cmp     ebx, 0x00
        jne     saving_loop2
        ; Para el ultimo nible______________
        ; El ultimo nible va a estar a distancia [Tamaño de buffer - tamaño a guardar]
        ; (en este caso 9 - 8 = 1) a la derecha del ultimo valor ingresado.
        mov     esi, [round_buffer_index]               ; Indice en nibles.
        mov     edx, esi
        shr     edx, 1                                  ; Indice en bytes.
        inc     edx                                     ; Me muevo una vez a la derecha
        mov     al, [round_buffer + edx]                ; Saco del buffer.
        and     al, 0x0F                                ; Parte baja del byte.
        shl     al, 4
        or      [saved_digits_table + edi], al
        inc     edi
        mov     [saved_digits_table_index], edi         ; Guardo el indice de la tabla en memoria.

        ; Limpio el buffer para el proximo numero.
        clean_buffer:
        ; [DEBUG]
        ;Para debuguear copio los numeros guardados en memoria a dos registros
        mov     ecx, [saved_digits_table_index]
        mov     eax, [saved_digits_table + ecx - 8]
        mov     ebx, [saved_digits_table + ecx - 4]
        mov     ecx, [round_buffer]
        mov     edx, 4
        mov     edx, [round_buffer + edx]
        ;BKPT
        ;[!DEBUG]

        mov     [saved_digits_table_index], di
        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        mov     [round_buffer_index], eax
        mov     ebx, round_buffer_size
            clean_cicle:
            mov     [round_buffer + ecx], ax
            inc     ecx
            cmp     ecx, ebx
            jnz     clean_cicle

; Fin de la rutina
exit:
        popad                        ;Popeo los registros de pila.
        ret
