;5. MODO PROTEGIDO 32 BITS
;
;En base al ejercicio anterior adecuarlo para que el mismo se ejecute en modo
;protegido 32bits.
;
;a) Crear una estructura GDT mínima con modelo de segmentación FLAT
;b) En la zona denominada Núcleo solo debe copiarse código.
;c) Definir una pila dentro del segmento de datos e inicializar el par de
;   registros SS:ESP adecuadamente. Realice la definición de forma dinámica de
;   modo que pueda modificarse su tamaño y ubicación de manera simple.
;
;El mapa de memoria para las diferentes secciones debe ser el siguiente:
;
;                   Sección                     |    Dirección inicial
;       ________________________________________|___________________________
;               Rutinas                         |        00000000h
;               Nucleo                          |        00200000h
;               Pila                            |        1FF08000h
;               Secuencia inicialización ROM    |        FFFF0000h
;               Vector de reset                 |        FFFFFFF0h
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Ejecucion:    make
; Limpeza:      make clean
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define BKPT    xchg    bx,bx

;______________________________________________________________________________;
;                           Modo protegido en 32 bits                          ;
;______________________________________________________________________________;

;________________________________________
; Traigo las variables externas
;________________________________________
GLOBAL Inicio_32bits

EXTERN Funcion_copia
EXTERN DS_SEL
EXTERN CS_SEL

EXTERN __STACK_START
EXTERN __STACK_END
EXTERN __COPY_DEST1
EXTERN __COPY_DEST2
EXTERN __COPY_DEST3
EXTERN __COPY_ORIG
EXTERN __COPY_LENGTH


USE32                   ;El codigo que continúa va en segmento de código
                                    ; de 32 BITS

;________________________________________
; Inicialización en 32 bits
;________________________________________
section .init32
Inicio_32bits:

        mov     ax, DS_SEL      ;Cargo DS con el selector que apunta al
        mov     ds, ax              ;descriptor de segmento de datos flat.
        mov     es, ax          ;Cargo ES

        mov     ss, ax              ;Inicio el selector de pila
        mov     esp, __STACK_END    ;Cargo el registro de pila y le doy
                                        ;direccion de inicio (recordar que se
                                        ;carga de arriba hacia abajo)

        BKPT

        ;Uso la pila para pasarle los calores a la funcion de copiado
        push    __COPY_ORIG     ;Posicion de origen .functions (en ROM) que contiene a .copy
        push    __COPY_DEST1    ;Posicion destino 0x00000000 (en RAM)
        push    __COPY_LENGTH   ;Largo de la seccion .functions que contiene a .copy
        call    __COPY_ORIG
        pop     eax             ;Saco los valores de la pila
        pop     eax
        pop     eax

        BKPT

        jmp     CS_SEL:Main

;________________________________________
; Seccion Main
;________________________________________
section .main
        ;Ahora estoy en RAM (0x00000000) entonces copio en las otras posiciones
Main:
        push    Funcion_copia   ;Posicion origen (en RAM)
        push    __COPY_DEST2    ;Posicion destino 0x00100000 (en RAM)
        push    __COPY_LENGTH   ;Largo de la seccion .functions que contiene .copy
        call    Funcion_copia
        pop     eax             ;Saco los valores de la pila
        pop     eax
        pop     eax

        BKPT

        push    Funcion_copia   ;Posicion origen (en RAM)
        push    __COPY_DEST3    ;Posicion destino 0x00200000 (en RAM)
        push    __COPY_LENGTH   ;Largo de la seccion .functions que contiene .copy
        call    Funcion_copia
        pop     eax             ;Saco los valores de la pila
        pop     eax
        pop     eax

        hlt
