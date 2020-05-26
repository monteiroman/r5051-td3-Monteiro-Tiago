/*____________________________________________________________________________*/
/*                            Pila de sistema                                 */
/*____________________________________________________________________________*/

__STACK_START = 0X1FF08000;
__STACK_SIZE = 0x00004000;
__STACK_END = __STACK_START + __STACK_SIZE;         /*Stack de 16k


/*____________________________________________________________________________*/
/*                            Pila de sistema                                 */
/*____________________________________________________________________________*/

__TASK1_STACK_START = 0X1FFFF000;
__TASK1_STACK_SIZE = 0x00004000;
__TASK1_STACK_END = __TASK1_STACK_START + __TASK1_STACK_SIZE;    /*Stack de 16k


/*____________________________________________________________________________*/
/*                         Areas de memoria                                   */
/*____________________________________________________________________________*/

MEMORY
{
  ram (rwx):        ORIGIN = 0x00000000,    LENGTH = 0xFFFF0000
  rom (rx):         ORIGIN = 0xFFFF0000,    LENGTH = 0xFFF0
  reset_bios (rx):  ORIGIN = 0xFFFFFFF0,    LENGTH = 0x10
}


/*____________________________________________________________________________*/
/*                         Areas de memoria                                   */
/*____________________________________________________________________________*/

SECTIONS
{
    /*________________________________________________________________________*/
    /*  INICIALIZACIONES                                                      */
    /*________________________________________________________________________*/
    .init 0xFFFF0000 :                                  /*Posiciono "." (vector de VMA) en 0xFFFF0000*/
		{
            __INIT_DEST = .;
            bin/init.elf(.ROM_init);                    /*Seccion que voy a copiar*/
            bin/init.elf(.init32);
            bin/exc_handlers.elf(.init32);
            bin/pic_init.elf(.init32);
            bin/bios.elf(.init32);
            bin/bios.elf(.main);
        } AT >rom                                       /*LMA donde se ubica*/
        __INIT_LENGTH = SIZEOF(.init);

    /*________________________________________________________________________*/
    /*  RUTINAS                                                               */
    /*________________________________________________________________________*/
    .routines 0x00000000 :
        {
            __ROUTINES_DEST = .;                        /*Lugar donde se va a cargar en VMA*/
            __ROUTINES_ORIG = LOADADDR(.routines);      /*Para saber en qie lugar de la ROM se guardo*/
            bin/exc_handlers.elf(.exc_handlers);        /*                      */
            bin/irq_handlers.elf(.irq_handlers);        /*                      */
            bin/keyboard.elf(.keyboard);                /*   Seccioes a copiar  */
            bin/keyboard.elf(.keyboard_table_init);     /*                      */
            bin/keyboard.elf(.keyboard_table);          /*                      */
            bin/timer.elf(.timer);                      /*                      */
        } AT >rom                                       /*Que se cargue en ROM -> LMA*/
        __ROUTINES_LENGTH = SIZEOF(.routines);          /*Tamaño de toda la seccion*/

    /*________________________________________________________________________*/
    /*  BUFFER DE VIDEO                                                       */
    /*________________________________________________________________________*/
    __VIDEO_BUFFER_ORIG = 0x000B8000;
    __VIDEO_BUFFER_SIZE = 0X00000FA0;                   /* 2 bytes * 80 caracteres * 25 lineas */

    /*________________________________________________________________________*/
    /*  TABLAS DEL SISTEMA                                                    */
    /*________________________________________________________________________*/
    .system_tables 0x00100000 :
        {
            __SYS_TABLES_DEST = .;
            bin/init.elf(.system_tables);
        }
        __SYS_TABLES_LENGTH = SIZEOF(.system_tables);

    /*________________________________________________________________________*/
    /*  TABLAS DE PAGINACION                                                  */
    /*________________________________________________________________________*/
    .paging_tables 0x00110000 :
        {
            __PAGING_TABLES_DEST = .;
            
        }
        __PAGING_TABLES_LENGTH = SIZEOF(.paging_tables);

    /*________________________________________________________________________*/
    /*  NUCLEO                                                                */
    /*________________________________________________________________________*/
    .kernel 0x00200000 :                                /*kernel en este caso la funcion copia y el dibujado de pantalla*/
        {
            __KERNEL_DEST = .;
            __KERNEL_ORIG = LOADADDR(.kernel);
            bin/copy.elf(.copy);
            bin/screen.elf(.screen);
        } AT >rom
        __KERNEL_LENGTH = SIZEOF(.kernel);

    /*________________________________________________________________________*/
    /*  DATOS                                                                 */
    /*________________________________________________________________________*/
    .data 0x00202000 :                                  /* Lugar donde va la variable que guarda la suma*/
        {
            __DATA_DEST = .;

        }
        __DATA_LENGTH = SIZEOF(.data);

    /*________________________________________________________________________*/
    /*  TABLA DE DIGITOS GUARDADOS                                            */
    /*________________________________________________________________________*/
    .saved_digits_table 0x00210000 :                    /* tabla de digitos guardados*/
        {
            __SAVED_DIGITS_TABLE_DEST = .;
            bin/timer.elf(.counter_bytes);
            bin/keyboard.elf(.saved_digits_table);
            bin/keyboard.elf(.round_buffer);
        }
        __SAVED_DIGITS_TABLE_LENGTH = SIZEOF(.saved_digits_table);

    /*________________________________________________________________________*/
    /*  TAREA 1                                                               */
    /*________________________________________________________________________*/
    .task1_text 0x00300000 :                            /* Donde se encuentra el codigo. */
        {
            __TASK1_TXT_DEST = .;
            __TASK1_TXT_ORIG = LOADADDR(.task1_text);
            bin/task1.elf(.task_one);
        } AT >rom
        __TASK1_TXT_LENGTH = SIZEOF(.task1_text);

    .task1_bss 0x00301000 :                             /* Seccion de datos no inicializados. */
        {
            __TASK1_BSS_DEST = .;
            bin/task1.elf(.sum_stored);
        }
        __TASK1_BSS_LENGTH = SIZEOF(.task1_bss);

    .task1_data_r 0x00302000 :                          /* Datos de solo lectura. */
        {
            __TASK1_DATA_R_DEST = .;
            __TASK1_DATA_R_ORIG = LOADADDR(.task1_data_r);

        } AT >rom
        __TASK1_DATA_R_LENGTH = SIZEOF(.task1_data_r);

    .task1_data_rw 0x00303000 :                         /* Datos lectura/escritura. */
        {
            __TASKS_DATA_RW_DEST = .;
            __TASKS_DATA_RW_ORIG = LOADADDR(.task1_data_rw);

        } AT >rom
        __TASKS_DATA_RW_LENGTH = SIZEOF(.task1_data_rw);

    /*________________________________________________________________________*/
    /*  RESET                                                                 */
    /*________________________________________________________________________*/
    .reset 0xFFFFFFF0 :
		{
            *(.reset);
        } AT >reset_bios
}
