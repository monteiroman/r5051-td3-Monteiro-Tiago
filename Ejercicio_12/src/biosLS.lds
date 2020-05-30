/*____________________________________________________________________________*/
/*                            Pila de sistema                                 */
/*____________________________________________________________________________*/

__STACK_LIN = 0x1FF08000;
__STACK_PHY = __STACK_LIN;
__STACK_SIZE = 0x00004000;                           /*Stack de 16k*/
__STACK_END = __STACK_LIN + __STACK_SIZE;


/*____________________________________________________________________________*/
/*                            Pila de sistema                                 */
/*____________________________________________________________________________*/

__TASK1_STACK_PHY = 0x1FFFF000;
__TASK1_STACK_LIN = 0x00713000;
__TASK1_STACK_SIZE = 0x00004000;                    /*Stack de 16k*/
__TASK1_STACK_END = __TASK1_STACK_LIN + __TASK1_STACK_SIZE;


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
    /*   OJO ESTO EN IDENTITY MAPPING                                         */
    /*                  Si no esta asi no puede hacer la paginación!!!        */
    /*________________________________________________________________________*/
    __INIT_PHY = 0xFFFF0000;
    .init 0xFFFF0000 :                                  /*Posiciono "." (vector de VMA) en 0xFFFF0000*/
		{
            __INIT_LIN = .;
            bin/init.elf(.ROM_init);                    /*Seccion que voy a copiar*/
            bin/init.elf(.init32);
            bin/exc_handlers.elf(.init32);
            bin/pic_init.elf(.init32);
            bin/bios.elf(.init32);
            bin/bios.elf(.main);
            bin/paging.elf(.init32);
        } AT >rom                                       /*LMA donde se ubica*/
        __INIT_LENGTH = SIZEOF(.init);

    /*________________________________________________________________________*/
    /*  RUTINAS                                                               */
    /*________________________________________________________________________*/
    __ROUTINES_PHY = 0x00000000;                        /*Dirección física*/
    .routines 0x00000000 :
        {
            __ROUTINES_LIN = .;                         /*Lugar donde se va a cargar en VMA*/
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
    __VIDEO_BUFFER_PHY = 0x000B8000;
    __VIDEO_BUFFER_LIN = 0x00010000;
    __VIDEO_BUFFER_SIZE = 0X00000FA0;                   /* 2 bytes * 80 caracteres * 25 lineas */

    /*________________________________________________________________________*/
    /*  TABLAS DEL SISTEMA                                                    */
    /*________________________________________________________________________*/
    __SYS_TABLES_PHY = 0x00100000;
    .system_tables 0x00100000 :
        {
            __SYS_TABLES_LIN = .;
            bin/init.elf(.system_tables);
        }
        __SYS_TABLES_LENGTH = SIZEOF(.system_tables);

    /*________________________________________________________________________*/
    /*  TABLAS DE PAGINACION                                                  */
    /*________________________________________________________________________*/
    __RUNTIME_PAGES_PHY = 0x08000000;
    __PAGING_TABLES_PHY = 0x00110000;
    .paging_tables 0x00110000 :
        {
            __PAGING_TABLES_LIN = .;
            bin/paging.elf(.paging_tables);
        }
        __PAGING_TABLES_LENGTH = SIZEOF(.paging_tables);

    /*________________________________________________________________________*/
    /*  NUCLEO                                                                */
    /*________________________________________________________________________*/
    __KERNEL_PHY = 0x00200000;                          /* NO PONER ENTRE LAS LLAVES!!!! */
    .kernel 0x01200000 :                                /*kernel en este caso la funcion copia y el dibujado de pantalla*/
        {
            __KERNEL_LIN = .;
            __KERNEL_ORIG = LOADADDR(.kernel);
            bin/copy.elf(.copy);
            bin/screen.elf(.screen);
        } AT >rom
        __KERNEL_LENGTH = SIZEOF(.kernel);

    /*________________________________________________________________________*/
    /*  DATOS                                                                 */
    /*________________________________________________________________________*/
    __DATA_PHY = 0x00202000;
    .data 0x01300000 :                                  /* Lugar donde va la variable que guarda la suma*/
        {
            __DATA_LIN = .;

        }
        __DATA_LENGTH = SIZEOF(.data);

    /*________________________________________________________________________*/
    /*  TABLA DE DIGITOS GUARDADOS                                            */
    /*________________________________________________________________________*/
    __SAVED_DIGITS_TABLE_PHY = 0x00210000;
    .saved_digits_table 0x01210000 :                    /* tabla de digitos guardados*/
        {
            __SAVED_DIGITS_TABLE_LIN = .;
            bin/timer.elf(.counter_bytes);
            bin/keyboard.elf(.saved_digits_table);
            bin/keyboard.elf(.round_buffer);
        }
        __SAVED_DIGITS_TABLE_LENGTH = SIZEOF(.saved_digits_table);

    /*________________________________________________________________________*/
    /*  TAREA 1                                                               */
    /*________________________________________________________________________*/
    __TASK1_TXT_PHY = 0x00300000;
    .task1_text 0x01301000 :                            /* Donde se encuentra el codigo. */
        {
            __TASK1_TXT_LIN = .;
            __TASK1_TXT_ORIG = LOADADDR(.task1_text);
            bin/task1.elf(.task_one);
        } AT >rom
        __TASK1_TXT_LENGTH = SIZEOF(.task1_text);

    __TASK1_BSS_PHY = 0x00301000;
    .task1_bss 0x01302000 :                             /* Seccion de datos no inicializados. */
        {
            __TASK1_BSS_LIN = .;
            bin/task1.elf(.sum_store);
        }
        __TASK1_BSS_LENGTH = SIZEOF(.task1_bss);

    __TASK1_DATA_R_PHY = 0x00302000;
    .task1_data_r 0x01202000 :                          /* Datos de solo lectura. */
        {
            __TASK1_DATA_R_LIN = .;
            __TASK1_DATA_R_ORIG = LOADADDR(.task1_data_r);

        } AT >rom
        __TASK1_DATA_R_LENGTH = SIZEOF(.task1_data_r);

    __TASK1_DATA_RW_PHY = 0x00303000;
    .task1_data_rw 0x01202000 :                         /* Datos lectura/escritura. */
        {
            __TASKS_DATA_RW_LIN = .;
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
