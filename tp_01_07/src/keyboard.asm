
%define BKPT    xchg    bx,bx

%define Keyb_Ctrl_Stat_Reg      0x64
%define Keyb_Out_Buffer_Reg     0x60

GLOBAL keyboard_fill_lookup_table
GLOBAL keyboard_routine

;Desde el linkerscript
EXTERN __SAVED_DIGITS_START
EXTERN __SAVED_DIGITS_END

;Desde handlers.asm
EXTERN IDT_handler_cleaner


;______________________________________________________________________________;
;                       Inicialización para el teclado                         ;
;______________________________________________________________________________;

;________________________________________
; Tabla para guardar los digitos
;________________________________________
;Aca voy a guardar los digitos ingresados. Se usa nobits para decirle al linker
;que esta sección va a existir pero que no le carge nada.
section .saved_digits_table nobits
        resb 64*1024                  ; Reservo Los 64k de la tabla (1024 x 64 bytes)

 ;________________________________________
 ; Tabla para identificar los digitos
 ; que se presionaron
 ;________________________________________
 ;Reservo el espacio para la tabla de digitos con espacio para añadir mas digitos
 ;en ejercicios posteriores.
section .keyboard_table nobits
table:
        resb 0xA6                   ;La hago pensando en que uso todas las teclas

;Lleno "table" con el codigo de los digitos que voy a necesitar. Esta parte va
;en ROM y se carga en el inicio.
USE32

section .keyboard_table_init
keyboard_fill_lookup_table:
        mov     ebp, table          ;Pongo la direccion de la tabla que se encuentra en ram

                    ;Posicion de teclado       Valor
        mov word        [ebp+0x02],             0x01    ;La lleno con cada valor de las teclas que
        mov word        [ebp+0x03],             0x02        ;pueden ser presionadas en este ej.
        mov word        [ebp+0x04],             0x03
        mov word        [ebp+0x05],             0x04
        mov word        [ebp+0x06],             0x05
        mov word        [ebp+0x07],             0x06
        mov word        [ebp+0x08],             0x07
        mov word        [ebp+0x09],             0x08
        mov word        [ebp+0x0A],             0x09
        mov word        [ebp+0x0B],             0x00
        mov word        [ebp+0x21],             0x0F

        mov word        [ebp+0x15],             0x00    ;Y
        mov word        [ebp+0x16],             0x06    ;U
        mov word        [ebp+0x17],             0x08    ;I
        mov word        [ebp+0x18],             0x0D    ;O

        ret


;______________________________________________________________________________;
;                           Rutina del teclado                                 ;
;______________________________________________________________________________;

section .keyboard
keyboard_routine:
        pushad                       ;Pusheo los registros a pila.

        mov     ebp, table           ;Busco la direccion de la tabla de inspeccion.
        xor     eax, eax             ;Pongo en 0 eax por las dudas.

        ;Inicio los punteros de las tablas de guardado de los caracteres.
        mov     esi, __SAVED_DIGITS_START - 1
        mov     edi,esi
        mov     edx, __SAVED_DIGITS_END

    buffer_check:
        in      al, Keyb_Ctrl_Stat_Reg      ;Miro el puerto 0x64 "Keyboard Controller Status Register".
        and     al, 0x01                    ;Obtengo el bit 0 "Output buffer status" haciendo una AND.
        cmp     al, 0x01                    ;Si "Output buffer status" vale 1 el buffer tiene informacion que se puede leer.
        jnz     buffer_check                ;Si está vacío sigo esperando.

        ;CMP hace la resta de las dos fuentes que se le pasan para saber si son
        ;iguales. Cuando lo son, la resta da cero -> se pone en 1 el flag de cero
        ;de EIP. En el caso anterior, si no son iguales JNZ salta a buffer_check
        ;de nuevo para seguir chequeando.

        in      al, Keyb_Out_Buffer_Reg     ;Miro el puerto 0x60 "Keyboard Output Buffer Register".
        mov     bl, al                      ;Copio lo leído en otro registro por prolijidad.
        and     bl, 0x80                    ;Obtengo el bit 7 "BRK" haciendo una AND.
        cmp     bl, 0x80                    ;0 -> Make (se presiono la tecla), 1 -> Break (se libero la tecla).
        jz      buffer_check                ;Se desea detectar cuando la tecla se suelta. Si fue presionada vuelvo a buffer_check.

        ;Si la tecla presionada y liberada es "F" salgo.
        cmp     al, 0x21
        jz      exit

        ;Chequeo si es mayor a 9. Si lo es salto a chequear si es Y, U, I, O.
        cmp     al, 0x0B
        jg      yuio_check

        ;Chequeo si es menor a 1 (solo "ESC"). Si lo es salto de nuevo a chequear
        ;el buffer del teclado.
        cmp     al, 0x02
        jl      buffer_check

        jmp     save_key        ;es un numero -> lo guardo

    yuio_check:
        ;***Y=#DE (Divide error, [0x00])***
        cmp     al, 0x15        ;Chequeo si es la Y
        jnz     not_Y           ;Si no es la Y sigo de largo.
        ;Genero la excepcion___________
        mov word    ebx, 0x0    ;Pongo en cero ebx
        div     ebx             ;Divido por cero
        ;______________________________
        not_Y:

        ;***U=#UD (Invalid Upcode, [0x06])***
        cmp     al, 0x16        ;Chequeo si es la U
        jnz     not_U           ;Si no es la U sigo de largo.
        ;Genero la excepcion___________
        UD2
        ;______________________________
        not_U:

        ;***I=#DF (Double Fault, [0x08])***
        cmp     al, 0x17        ;Chequeo si es la I
        jnz     not_I           ;Si no es la I sigo de largo.
        ;Genero la excepcion___________
        xor     ebx, ebx        ;Pongo en cero ebx
        push    ebx             ;Pusheo 0 a la proxima funcion para que borre el
        call    IDT_handler_cleaner ; handler de DE.
        pop     eax
        div     ebx             ;Divido por cero pero como no esta el handler
        ;______________________________
        not_I:                  ;   tengo DF

        ;***O=#GP (General Protection, [0x0D])***
        cmp     al, 0x18        ;Chequeo si es la O
        jnz     not_O           ;Si no es la O sigo de largo.
        ;Genero la excepcion___________
        mov     [cs:yuio_check], eax  ;Intento escribir segmento de codigo.
        ;______________________________
        not_O:

        jmp     buffer_check    ;Si no es ninguna de las excepciones, sigo
                                ;   preguntando por el teclado.

    save_key:
        ;Ya puedo guardar el valor de la tecla en la tabla.
        ;En "al" ya tenia el valor que presionaron, si le sumo ebp obtengo,
        ;desde la lookup table, el valor de la tecla que apretaron.
        mov     cl, [ebp+eax]

        ;Chequeo si el inicio y el final son iguales. Si lo son estoy por entrar
        ;en overflow, entonces vuelvo al principio con 'mov edi,esi'. Si no lo
        ;son, puedo seguir guardando.
        cmp     edi, edx
        jnz     not_overflow
        mov     edi,esi

        ;Incremento el indice y guardo el valor de "cl" (que es el que se obtenia
        ;de la lookup table) en [edi] (que seria el puntero de la tabla de
        ;guardado).
        not_overflow:
        inc     edi
        mov     [edi], cl

        jmp buffer_check

exit:
        popad                        ;Popeo los registros de pila.
        ret
