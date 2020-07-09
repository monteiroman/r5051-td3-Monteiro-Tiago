; Informacion importante aca: https://wiki.osdev.org/PIC

;PIC
%define Master_PIC_Command      0x20
%define Master_PIC_Data         0x21
%define Master_Intrr_type       0x20
%define Slave_PIC_Command       0xA0
%define Slave_PIC_Data          0xA1
%define Slave_Intrr_type        0x28

;PIT
%define Mode_Command_register   0x43
%define Channel_0_data_port     0x40

USE32

GLOBAl pic_init

section .init32 progbits

pic_init:
; Inicializar controlador de teclado.
        mov     al, 0xFF                    ;Enviar comando de reset al controlador
        out     0x64, al                    ;de teclado
        mov     ecx, 256                    ;Esperar que rearranque el controlador.
        loop $
        mov     ecx, 0x10000
    ciclo1:
        in      al, 0x60                    ;Esperar que termine el reset del controlador.
        test    al, 1
        loopz ciclo1
        mov     al, 0xF4                    ;Habilitar el teclado.
        out     0x64, al
        mov     ecx, 0x10000
    ciclo2:
        in      al, 0x60                    ;Esperar que termine el comando.
        test    al, 1
        loopz ciclo2
        in      al, 0x60                    ;Vaciar el buffer de teclado.
    ; Inicializar timer para que interrumpa cada 54.9 milisegundos.
        mov     al, 00110100b               ;Canal cero, byte bajo y luego byte alto.
        out     Mode_Command_register, al
        mov     ax, 11932                   ;1.193182MHz * 10ms = 11932 Ticks de 10ms
        out     Channel_0_data_port, al     ;Programo pa parte baja.
        mov     al, ah
        out     Channel_0_data_port, al     ;Programo pa parte alta.

    ; Inicializar ambos PIC usando ICW (Initialization Control Words).
    ; ICW1 = Indicarle a los PIC que estamos inicializándolo.
        mov al,0x11                 ;Palabra de inicialización (bit 4=1) indicando que
                                    ;   se necesita ICW4 (bit 0=1)
        out Master_PIC_Command,al   ;Enviar ICW1 al primer PIC.
        out Slave_PIC_Command,al    ;Enviar ICW1 al segundo PIC.

    ; ICW2 = Indicarle a los PIC cuales son los vectores de interrupciones.
        mov al,Master_Intrr_type    ;El primer PIC va a usar los tipos de interr 0x20-0x27.
        out Master_PIC_Data,al      ;Enviar ICW2 al primer PIC.
        mov al,Slave_Intrr_type     ;El segundo PIC va a usar los tipos de interr 0x28-0x2F.
        out Slave_PIC_Data,al       ;Enviar ICW2 al segundo PIC.

    ; ICW3 = Indicarle a los PIC como se conectan como master y slave.
        mov al,4                    ;Decirle al primer PIC que hay un PIC esclavo en IRQ2.
        out Master_PIC_Data,al      ;Enviar ICW3 al primer PIC.
        mov al,2                    ;Decirle al segundo PIC su ID de cascada (2).
        out Slave_PIC_Data,al       ;Enviar ICW3 al segundo PIC.

    ; ICW4 = Información adicional sobre el entorno.
        mov al,1                    ;Poner el PIC en modo 8086.
        out Master_PIC_Data,al      ;Enviar ICW4 al primer PIC.
        out Slave_PIC_Data,al       ;Enviar ICW4 al segundo PIC.

    ; Indicar cuales son los IRQ habilitados.
        mov al,0xFC                 ;Deshabilito todas las interrupciones menos la de teclado
        out Master_PIC_Data,al      ;Enviar máscara al primer PIC.
        mov al, 0xFF
        out Slave_PIC_Data,al       ;Enviar máscara al segundo PIC.

        ret
