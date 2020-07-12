;Mas info acá:  https://wiki.osdev.org/Printing_To_Screen
;               https://wiki.osdev.org/Text_UI
%define BKPT    xchg    bx,bx

; Limites de la pantalla : row ----> 0x18
;                          column -> 0x4F
%define     sign_row_offset         0x16    ; OJO!!: Valores maximos:  sign_row_offset->0x16
%define     sign_column_offset      0x33    ;                          sign_column_offset->0x33
                                            ; Si me paso se rompe todo.
%define     num_row_offset          0x0A
%define     num_column_offset       0x19
%define     num_row_offset_2        0x0B
%define     num_column_offset_2     0x19

; Color de fuente
%define     fontColor_Green         0x02
; Color de fondo
%define     fontBackground_Black    0x00

; Identificador de Tarea
%define     task1_id    0x01
%define     task2_id    0x02

; Codigo ASCII
%define     ASCII_A     0x41
%define     ASCII_B     0x42
%define     ASCII_C     0x43
%define     ASCII_D     0x44
%define     ASCII_E     0x45
%define     ASCII_F     0x46
%define     ASCII_G     0x47
%define     ASCII_H     0x48
%define     ASCII_I     0x49
%define     ASCII_J     0x4A
%define     ASCII_K     0x4B
%define     ASCII_L     0x4C
%define     ASCII_M     0x4D
%define     ASCII_N     0x4E
%define     ASCII_O     0x4F
%define     ASCII_P     0x50
%define     ASCII_Q     0x51
%define     ASCII_R     0x52
%define     ASCII_S     0x53
%define     ASCII_T     0x54
%define     ASCII_U     0x55
%define     ASCII_V     0x56
%define     ASCII_W     0x57
%define     ASCII_X     0x58
%define     ASCII_Y     0x59
%define     ASCII_Z     0x60
; Numeros
%define     ASCII_0     0x30
; Simbolos
%define     ASCII_OPAR  0x28    ; (
%define     ASCII_CPAR  0x29    ; )
%define     ASCII_DASH  0x2D    ; -
%define     ASCII_BLANK 0x20    ; Espacio
%define     ASCII_TAG   0x23    ; #
%define     ASCII_COLON 0x3A    ; :
%define     ASCII_DOT   0x2E    ; .


GLOBAL print_sign
GLOBAL exc_warning
GLOBAL print_result

; Desde task1.asm
EXTERN sum_stored

; Desde task2.asm
EXTERN sum_stored_2

; Desde biosLS.asm
EXTERN  __VIDEO_BUFFER_LIN

USE32

;______________________________________________________________________________;
;                           Manejador de pantalla                              ;
;                            80 x 25  ( W x H )                                ;
;______________________________________________________________________________;
section .screen
print_sign:
        call    sign

        call    Title

        ;push    task1_id
        ;push    num_row_offset
        ;push    num_column_offset
        ;push    sum_stored
        ;call    print_result
        ;pop     eax
        ;pop     eax
        ;pop     eax
        ;pop     eax

        ;push    task2_id
        ;push    num_row_offset_2
        ;push    num_column_offset_2
        ;push    sum_stored_2             
        ;call    print_result
        ;pop     eax
        ;pop     eax
        ;pop     eax
        ;pop     eax

        
        
        ret


;________________________________________
; MBI supercompiuter
;________________________________________
Title:
        mov     edi, __VIDEO_BUFFER_LIN
        add     edi, 0x32A
        mov     al, ASCII_S
        call    print_char
        mov     al, ASCII_U
        call    print_char
        mov     al, ASCII_P
        call    print_char
        mov     al, ASCII_E
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_C
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_M
        call    print_char
        mov     al, ASCII_P
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_U
        call    print_char
        mov     al, ASCII_T
        call    print_char
        mov     al, ASCII_E
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_M
        call    print_char
        mov     al, ASCII_B
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_OPAR
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_CPAR
        call    print_char

        ret

;________________________________________
; Imprimir el Resultado de la Suma
;________________________________________
print_result:
        mov     ebp, esp                        ; Copio el puntero a pila para no romper nada
        
        mov     edi, __VIDEO_BUFFER_LIN         ; Direccion de inicio de la memoria de video

        mov     eax, [ebp + 0x0C]               ; Traigo el offset de fila
        mov     ebx, 0xA0                       ; 80 * 2 = 160 -> 0xA0
        mul     bx                              ; Multiplico por 160 para ubicarme en altura
        add     edi, eax                        ; Sumo ubicacion horizontal

        mov     ebx, [ebp + 0x08]               ; Traigo el offset de columna
        shl     ebx, 1                          ; Multiplico por dos para ubicarme en el byte
        add     edi, ebx                        ; Sumo la ubicacion horizontal

        mov     bl, fontColor_Green             ; Agrego el color de la fuente
        or      bl, fontBackground_Black        ; No es necesario pero para futuro

        mov     ecx, [ebp + 0x04]
        mov     edx, [ecx + 0x04]               ; Parte alta del numero
        mov     ecx, [ecx]                      ; Parte baja del numero

    ; Imprimo el titulo _____________________________________
        mov     al, ASCII_T
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_T
        call    print_char
        mov     al, ASCII_A
        call    print_char
        mov     al, ASCII_L
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_T
        call    print_char
        mov     al, ASCII_A
        call    print_char
        mov     al, ASCII_S
        call    print_char
        mov     al, ASCII_K
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_TAG
        call    print_char

        mov     al, [ebp + 0x10]                ; Busco y muestro el numero de tarea
        call    ASCII_decode
        call    print_char

        mov     al, ASCII_COLON
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_0
        call    print_char
        mov     al, ASCII_X
        call    print_char

        add     edi, 0x02                       ; Muevo edi para que no se pise el numero con el titulo
    ; Primeros 8 numeros _____________________________________
    ; Para la parte baja
        add     edi, 0x0C                       ;Me muevo hasta la mitad del numero
        mov     eax, edx
        and     eax, 0x0F0F0F0F                 ; Mascara para todas las partes bajas
        mov     esi, 0x04                       ; Cantidad de veces que hago el loop
        ;BKPT
        first_low:
            call    ASCII_decode                ; Decodifico el ascii del caracter.
            call    print_char                  ; Imprimo.
            sub     edi, 0x06                   ; Resto 4 para pararme en el proximo nible de los bajos y
                                                ;   2 para poder usar print_char (ya la tenia).
            shr     eax, 8                      ; Muevo 8 lugares a la derecha para encontrarme con la otra parte baja.
            dec     esi                         ; Una vez menos...
            cmp     esi, 0x00                   ; Chequeo condicion de fin
        jne     first_low

    ; Para la parte alta
        add     edi, 0x0E                       ; El loop anterior me deja 6 por debajo el valor de edi, hay que sumarlo
                                                ;  y restar 2 para ubicar al primer nible de los de mas peso en su lugar.
        mov     eax, edx
        and     eax, 0xF0F0F0F0                 ; Mascara para todas las partes bajas
        mov     esi, 0x04                       ; Cantidad de veces que hago el loop
        shr     eax, 4                          ; Me muevo a la derecha 4 posiciones para quedar con las partes altas
        first_high:
            call    ASCII_decode                ; Decodifico el ascii del caracter.
            call    print_char                  ; Imprimo.
            sub     edi, 0x06                   ; Resto 4 para pararme en el proximo nible de los bajos y
                                                ;   2 para poder usar print_char (ya la tenia).
            shr     eax, 8                      ; Muevo 8 lugares a la derecha para encontrarme con la otra parte alta.
            dec     esi                         ; Una vez menos...
            cmp     esi, 0x00                   ; Chequeo condicion de fin
        jne     first_high

    ; Ultimos 8 numeros _____________________________________
    ; Para la parte baja
        add     edi, 0x0A                       ; Compenso el loop anterior
        add     edi, 0x18                       ; Me muevo hasta el final del numero
        mov     eax, ecx
        and     eax, 0x0F0F0F0F                 ; Mascara para todas las partes bajas
        mov     esi, 0x04                       ; Cantidad de veces que hago el loop
        ;BKPT
        second_low:
            call    ASCII_decode                ; Decodifico el ascii del caracter.
            call    print_char                  ; Imprimo.
            sub     edi, 0x06                   ; Resto 4 para pararme en el proximo nible de los bajos y
                                                ;   2 para poder usar print_char (ya la tenia).
            shr     eax, 8                      ; Muevo 8 lugares a la derecha para encontrarme con la otra parte baja.
            dec     esi                         ; Una vez menos...
            cmp     esi, 0x00                   ; Chequeo condicion de fin
        jne     second_low

    ; Para la parte alta
        add     edi, 0x0E                       ; El loop anterior me deja 6 por debajo el valor de edi, hay que sumarlo
                                                ;  y restar 2 para ubicar al primer nible de los de mas peso en su lugar.
        mov     eax, ecx
        and     eax, 0xF0F0F0F0                 ; Mascara para todas las partes bajas
        mov     esi, 0x04                       ; Cantidad de veces que hago el loop
        shr     eax, 4                          ; Me muevo a la derecha 4 posiciones para quedar con las partes altas
        second_high:
            call    ASCII_decode                ; Decodifico el ascii del caracter.
            call    print_char                  ; Imprimo.
            sub     edi, 0x06                   ; Resto 4 para pararme en el proximo nible de los bajos y
                                                ;   2 para poder usar print_char (ya la tenia).
            shr     eax, 8                      ; Muevo 8 lugares a la derecha para encontrarme con la otra parte alta.
            dec     esi                         ; Una vez menos...
            cmp     esi, 0x00                   ; Chequeo condicion de fin
        jne     second_high

        ret


; Decodificar ASCII, recive el valor en "al" y devuelve el Codigo
; ahí mismo.
    ASCII_decode:
        cmp     al, 0x09                        ; Si es mayor a 9 no es un numero
        jg      not_num
            mov     ebp, ASCII_0
            add     ax, bp
            ret
        not_num:
        mov     ebp, ASCII_A
        sub     ax, 0x0A
        add     ax, bp
        ret


;________________________________________
; Firma
;________________________________________
sign:
        mov     ebp, __VIDEO_BUFFER_LIN
        mov     edi, __VIDEO_BUFFER_LIN
        ;BKPT

        ; Primera linea_______________________
        mov     eax, sign_row_offset
        mov     ebx, 0xA0                       ; 80 * 2 = 160 -> 0xA0
        mul     bx                              ; Multiplico por 160 para ubicarme en altura
        add     edi, eax                        ; Sumo ubicacion horizontal

        mov     ebx, sign_column_offset
        shl     ebx, 1                          ; Multiplico por dos para ubicarme en el byte
        add     edi, ebx                        ; Sumo la ubicacion horizontal

        mov     bl, fontColor_Green             ; Agrego el color de la fuente
        or      bl, fontBackground_Black        ; No es necesario pero para futuro

        mov     ecx, 0x1D                       ; Voy a imprimir 27 asteriscos
        sign_loop1:
            mov     al, ASCII_TAG
            call    print_char

            dec     ecx
            cmp     ecx, 0x00
        jne     sign_loop1

        ; Nombre y legajo_______________________
        mov     edi, ebp                        ; Reestablezco la posicion del buffer

        mov     eax, sign_row_offset
        inc     eax                             ; Bajo una posicion para el nombre
        mov     ebx, 0xA0                       ; 80 * 2 = 160 -> 0xA0
        mul     bx                              ; Multiplico por 160 para ubicarme en altura
        add     edi, eax                        ; Sumo ubicacion horizontal

        mov     ebx, sign_column_offset
        shl     ebx, 1                          ; Multiplico por dos para ubicarme en el byte
        add     edi, ebx                        ; Sumo la ubicacion horizontal

        mov     bl, fontColor_Green             ; Agrego el color de la fuente
        or      bl, fontBackground_Black        ; No es necesario pero para futuro

        mov     al, ASCII_TAG
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_T
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_A
        call    print_char
        mov     al, ASCII_G
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_M
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_N
        call    print_char
        mov     al, ASCII_T
        call    print_char
        mov     al, ASCII_E
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_OPAR
        call    print_char
        mov     al, ASCII_0
        add     al, 0x01
        call    print_char
        mov     al, ASCII_0
        add     al, 0x04
        call    print_char
        mov     al, ASCII_0
        add     al, 0x02
        call    print_char
        mov     al, ASCII_0
        call    print_char
        mov     al, ASCII_0
        add     al, 0x03
        call    print_char
        mov     al, ASCII_0
        add     al, 0x05
        call    print_char
        mov     al, ASCII_DASH
        call    print_char
        mov     al, ASCII_0
        add     al, 0x05
        call    print_char
        mov     al, ASCII_CPAR
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_TAG
        call    print_char

        ; Segunda linea_______________________
        mov     edi, ebp                        ; Reestablezco la posicion del buffer

        mov     eax, sign_row_offset
        add     eax, 0x02                       ; Bajo dos posiciones para la ultima linea
        mov     ebx, 0xA0                       ; 80 * 2 = 160 -> 0xA0
        mul     bx                              ; Multiplico por 160 para ubicarme en altura
        add     edi, eax                        ; Sumo ubicacion horizontal

        mov     ebx, sign_column_offset
        shl     ebx, 1                          ; Multiplico por dos para ubicarme en el byte
        add     edi, ebx                        ; Sumo la ubicacion horizontal

        mov     bl, fontColor_Green             ; Agrego el color de la fuente
        or      bl, fontBackground_Black        ; No es necesario pero para futuro

        mov     ecx, 0x1D                       ; Voy a imprimir 27 asteriscos
        sign_loop2:
            mov     al, ASCII_TAG
            call    print_char
            dec     ecx
            cmp     ecx, 0x00
        jne     sign_loop2

        ret

; Imprimir caracter
; caracter "al" con atributos
; "bl"  en posicion "edi"
print_char:
        ;BKPT
        mov     [edi], al
        inc     edi
        mov     [edi], bl
        inc     edi

        ret


;________________________________________
; Aviso de Excepcion
;________________________________________
exc_warning:
        mov     edi, __VIDEO_BUFFER_LIN
        mov     bl, 0x4f
        add     edi, 0x42A
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_C
        call    print_char
        mov     al, ASCII_U
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_U
        call    print_char
        mov     al, ASCII_N
        call    print_char
        mov     al, ASCII_A
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_E
        call    print_char
        mov     al, ASCII_X
        call    print_char
        mov     al, ASCII_C
        call    print_char
        mov     al, ASCII_E
        call    print_char
        mov     al, ASCII_P
        call    print_char
        mov     al, ASCII_C
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_O
        call    print_char
        mov     al, ASCII_N
        call    print_char
        mov     al, ASCII_DOT
        call    print_char
        add     edi, 0x80
        mov     al, ASCII_M
        call    print_char
        mov     al, ASCII_I
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_A
        call    print_char
        mov     al, ASCII_R
        call    print_char
        mov     al, ASCII_BLANK
        call    print_char
        mov     al, ASCII_E
        call    print_char
        mov     al, ASCII_D
        call    print_char
        mov     al, ASCII_X
        call    print_char
        mov     al, ASCII_DOT
        call    print_char

        ret

