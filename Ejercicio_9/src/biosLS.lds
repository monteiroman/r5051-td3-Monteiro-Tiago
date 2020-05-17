/*____________________________________________________________________________*/
/*                            Etiquetas                                       */
/*____________________________________________________________________________*/

__STACK_START = 0X1FF08000;
__STACK_SIZE = 0x00004000;
__STACK_END = __STACK_START + __STACK_SIZE;         /*Stack de 16k


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
	.init 0xFFFF0000 :                              /*Posiciono "." (vector de VMA) en 0xFFFF0000*/
		{
            bin/init.elf(.ROM_init);                    /*Seccion que voy a copiar*/
            bin/init.elf(.init32);
            bin/exc_handlers.elf(.init32);
            bin/pic_init.elf(.init32);
            bin/bios.elf(.init32);
            bin/bios.elf(.main);
        } AT >rom                                   /*LMA donde se ubica*/

    .reset 0xFFFFFFF0 :
		{
            *(.reset);
        } AT >reset_bios

    .routines 0x00000000 :                          /* rutina del teclado*/
        {
            __ROUTINES_DEST = .;
            __ROUTINES_ORIG = LOADADDR(.routines);
            bin/exc_handlers.elf(.exc_handlers);
            bin/irq_handlers.elf(.irq_handlers);
            bin/keyboard.elf(.keyboard);
            bin/keyboard.elf(.keyboard_table_init);
            bin/keyboard.elf(.keyboard_table);
            bin/timer.elf(.timer);
        } AT >rom
        __ROUTINES_LENGTH = SIZEOF(.routines);

    .system_tables 0x00100000 :
        {
            __SYS_TABLES_DEST = .;
            __SYS_TABLES_ORIG = LOADADDR(.system_tables);
            bin/init.elf(.system_tables);
        }
        __SYS_TABLES_LENGTH = SIZEOF(.system_tables);

    .kernel 0x00200000 :                            /*kernel en este caso la funcion copia*/
        {
            __KERNEL_DEST = .;
            __KERNEL_ORIG = LOADADDR(.kernel);
            bin/copy.elf(.copy);
        } AT >rom
        __KERNEL_LENGTH = SIZEOF(.kernel);

    .data 0x00202000 :                              /* Lugar donde van las tablas y el codigo que las inicia*/
        {
            bin/task1.elf(.sum_stored);
        }

    .saved_digits_table 0x00210000 :                  /* tabla de digitos guardados*/
        {
            bin/timer.elf(.counter_bytes);
            bin/keyboard.elf(.saved_digits_table);
            bin/keyboard.elf(.round_buffer);
        }

    .tasks 0x00300000 :
        {
            __TASKS_DEST = .;
            __TASKS_ORIG = LOADADDR(.tasks);
            bin/task1.elf(.task_one);
        } AT >rom
        __TASKS_LENGTH = SIZEOF(.tasks);
}
