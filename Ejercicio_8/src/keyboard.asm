
%define BKPT    xchg    bx,bx

%define Keyb_Ctrl_Stat_Reg      0x64
%define Keyb_Out_Buffer_Reg     0x60

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
    round_buffer:
        resb 9                        ; Reservo los bytes del buffer circular.
        round_buffer_end:

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

        ;Si la tecla presionada y liberada es "F" salgo.
        cmp     al, 0x21
        jz      exit

        ;Chequeo si es mayor a la tecla "0". Si lo es salto a chequear el buffer
        cmp     al, 0x0B
        jg      exit

        ;Chequeo si es menor a la tecla "1" (solo "ESC"). Si lo es salto de
        ;nuevo a chequear el buffer del teclado.
        cmp     al, 0x02
        jl      exit

        jmp     save_number        ;es un numero -> lo guardo


    save_number:

        mov     ebp, table           ;Busco la direccion de la tabla de inspeccion.

        ;Inicio los punteros de las tablas de guardado de los caracteres.
        xor     ebx, ebx
        mov     bl, [round_buffer_index]
        mov     edx, round_buffer_end

        ;Ya puedo guardar el valor de la tecla en la tabla.
        ;En "al" ya tenia el valor que presionaron, si le sumo ebp obtengo,
        ;desde la lookup table, el valor de la tecla que apretaron.
        xor     ecx,ecx
        mov     cl, [ebp+eax]
BKPT
        ;Chequeo si estoy por sobrepasar el buffer
        mov     edi, round_buffer           ;Guardo el inicio del buffer en edi
        xor     ebx,ebx
        xor     eax,eax
        mov     bl, 0x2
        mov     eax, [round_buffer_index]
        div     bl
        add     eax, ebx                    ;sumo eax y ebx para tener la posicion exacta en el buffer
        cmp     eax, edx
        jnz     round_buffer_not_overflow   ;Si no hizo overflow salto la proxima instruccion que
        mov     bx,0                        ; pone al indice en cero

        ;Incremento el indice y guardo el valor de "cl" (que es el que se obtenia
        ;de la lookup table) en el inicio de la tabla + edi (que seria el puntero
        ;de la tabla de guardado).
        round_buffer_not_overflow:

        xor     ebx, ebx
        mov     bl, [round_buffer_index]
        ;BKPT
        xor     eax, eax
        xor     edx, edx
        mov     ax, bx          ;Divido ax por dos, en la parte baja guardo el resultado,
        mov     dl, 0x2         ; en la parte alta el resto.
        div     dl

        and     ah, 0x01                ;Me fijo en el ultimo bit de la parte alta de ax, me dice si el indice es par o impar
        cmp     ah, 0x01                ; si el indice es impar lo tengo que guardar un nible corrido
        jz      not_even_index
            xor     edx, edx
            mov     dl, al
            mov     [round_buffer + edx], cl
            jmp     saving_end
        not_even_index:
            xor     dx, dx
            mov     dl, al
            shl     cx, 4
            add     [round_buffer + edx], cx

        saving_end:
        inc     bx
        mov     [round_buffer_index], bl     ;guardo el indice

        jmp     exit




;;;;;;;;;;;;;;;;;;;;;;;;;;; esta guarda en la tabla. por ahora la dejo aca
    save_key:
        mov     ebp, table           ;Busco la direccion de la tabla de inspeccion.

        ;Inicio los punteros de las tablas de guardado de los caracteres.
        xor     esi, esi
        xor     edi, edi
        mov     esi, [saved_digits_table_index]
        mov     di, si
        mov     edx, saved_digits_table_end

        ;Ya puedo guardar el valor de la tecla en la tabla.
        ;En "al" ya tenia el valor que presionaron, si le sumo ebp obtengo,
        ;desde la lookup table, el valor de la tecla que apretaron.
        mov     cl, [ebp+eax]

        ;Chequeo si el inicio y el final son iguales. Si lo son estoy por entrar
        ;en overflow, entonces vuelvo al principio con 'mov edi,esi'. Si no lo
        ;son, puedo seguir guardando.
        cmp     [saved_digits_table + edi], edx
        jnz     not_overflow
        mov     di,si

        ;Incremento el indice y guardo el valor de "cl" (que es el que se obtenia
        ;de la lookup table) en el inicio de la tabla + edi (que seria el puntero
        ;de la tabla de guardado).
        not_overflow:
        mov     [saved_digits_table + edi], cl
        inc     di
        mov     [saved_digits_table_index], di     ;guardo el indice

exit:
        popad                        ;Popeo los registros de pila.
        ret
