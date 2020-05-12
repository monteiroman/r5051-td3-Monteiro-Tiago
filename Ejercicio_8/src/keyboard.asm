
%define BKPT    xchg    bx,bx

%define Keyb_Ctrl_Stat_Reg      0x64
%define Keyb_Out_Buffer_Reg     0x60

%define number_bytes   8

GLOBAL keyboard_fill_lookup_table
GLOBAL keyboard_routine

GLOBAL loop_buffer

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
    saved_digits_table_index:
        resb 2                        ; Reservo dos bytes para indice
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
        resb 1
    round_buffer_is_overflown:
        resb 1
    round_buffer:
        resb 9                        ; Reservo los bytes del buffer circular.
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
        add     edi, ebx                    ; Sumo ebx y edi para tener la posicion exacta en el buffer
        cmp     edi, edx                    ; Comparo con el final del buffer.
        jnz     round_buffer_not_overflow   ; Si hizo overflow, reseteo el indice
          mov     bl,0                      ;    que venia manejando en ebx
          mov     [round_buffer_index], bl  ; Guardo el indice reseteado
          mov     ebx, 1
          mov     [round_buffer_is_overflown], bl     ; Dejo aviso que se sobrepaso el buffer
                                                        ;   aunque sea una vez

        ;Una vez solucionada la parte de overflow
        round_buffer_not_overflow:
        xor     ebx, ebx                        ; Limpio registros.
        xor     eax, eax
        xor     edx, edx
        mov     bl, [round_buffer_index]        ; Vuelvo a cargar el indice (antes estaba dividido por dos)
        mov     ax, bx
        mov     dl, 0x2                         ; Al valor del indice lo divido por dos y me fijo si es impar o par. DIV guarda el resultado
        div     dl                              ;    de la division en la parte baja de ax y el resto en la parte alta.

        and     ah, 0x01                        ; Me fijo en el ultimo bit de la parte alta de ax, me dice si el indice es par o impar
        cmp     ah, 0x01                        ;     si el indice es impar lo tengo que guardar un nible corrido
        jz      not_even_index
            xor     edx, edx                    ; Si es par, tengo que guardar el numero donde dice al
            mov     dl, al                      ; Guardo al en dl para usarlo de puntero.
            mov     al, 0xF0                    ; Hago una mascara para poner a cero el primer nible
            and     [round_buffer + edx], al    ; Pongo a cero el primer nible.
            add     [round_buffer + edx], cl    ; Le cargo el valor.
            jmp     saving_end                  ; Termino de guardar.
        not_even_index:
            xor     dx, dx                      ; Si es impar, tengo que guardar el numero donde dice al
            mov     dl, al                      ; Guardo al en dl para usarlo de puntero.
            mov     al, 0x0F                    ; Hago una mascara para poner a cero el segundo nible
            and     [round_buffer + edx], al    ; Pongo a cero el segundo nible.
            shl     cx, 4                       ; Corro mi numero a grardar 4 veces para que quede en la parte alta.
            add     [round_buffer + edx], cx    ; Cargo el valor en el buffer.
        saving_end:
        inc     bx
        mov     [round_buffer_index], bl     ;guardo el indice

        jmp     exit


;________________________________________
; Funcion de guardado de numeros
; del buffer en la tabla.
;________________________________________
    save_buffer:
        ;Inicio los punteros de las tablas de guardado de los caracteres.
        xor     esi, esi
        xor     edi, edi
        mov     esi, [saved_digits_table_index]
        mov     di, si
        mov     edx, saved_digits_table_end

        ;Chequeo si el inicio y el final son iguales. Si lo son estoy por entrar
        ;en overflow, entonces vuelvo al principio con 'mov edi,esi'. Si no lo
        ;son, puedo seguir guardando.
        cmp     [saved_digits_table + edi], edx
        jnz     not_overflow
            mov     di,0
            mov     [saved_digits_table_index], di

        ;Incremento el indice y guardo el valor de "cl" (que es el que se obtenia
        ;de la lookup table) en el inicio de la tabla + edi (que seria el puntero
        ;de la tabla de guardado).
        not_overflow:
        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     edx, edx
        mov     eax, 1
        cmp     al, [round_buffer_is_overflown]
        mov     cl, number_bytes                ; Cantidad de bytes que voy a copiar
        jz      overflowed_round_buffer
        ; Si el buffer no se sobrepaso, lo copio asi como esta a la tabla de digitos
        ; guardados.
            direct_copy:
            mov     bl, [round_buffer + edx]        ; Saco el valor del buffer. En este caso empiezo desde cero.
            mov     [saved_digits_table + edi], bl  ; Lo guardo en la tabla.
            inc     edx                             ; Incremento el indice con el que me muevo en el buffer
            inc     di                              ; Incremento el indice con el que me muevo en la tabla.
            cmp     edx, ecx                        ; Comparo, si el indice del buffer es igual a la cantidad de bytes
            jz      clean_buffer                    ;   que necesito, me voy.
            jmp     direct_copy                     ; Si no es igual, sigo sacando del buffer.
        ; Si el buffer se desbordó, la operatoria es diferente,
            overflowed_round_buffer:
            mov     dl, [round_buffer_index]        ; Obtengo el indice de digito donde quedo el buffer.
            shr     dl,1                            ; Lo divido por dos para saber el byte que corresponde.
            inc     edx                             ; Incremento 1 para ir al inicio de lo que tengo que
            overflowed_cicle:                       ;     levantar (tamaño de buffer - tamaño dato a guardar).
            mov     bl, [round_buffer + edx]        ; Saco el valor del buffer.
            mov     [saved_digits_table + edi], bl  ; Lo guardo en la tabla.
            inc     edx
            inc     di
            mov     esi, round_buffer_end
            mov     eax, round_buffer
            add     eax,edx
            cmp     eax, esi                        ; Comparo el final del buffer con la posicion en la que estoy.
            jnz     not_end
                mov     edx, 0                      ; Si es el final del buffer vuelvo al principio.
            not_end:
            dec     ecx                             ; Decremento la cantidad de veces que tengo que hacer este ciclo.
            cmp     ecx,0
            jnz     overflowed_cicle                ; Comparo para saber si ya saque los 8 valores.
            jmp     clean_buffer

        clean_buffer:                               ; Limpio el buffer temporal
        mov     [saved_digits_table_index], di
        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        mov     [round_buffer_index], ax
        mov     [round_buffer_is_overflown], ax
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
