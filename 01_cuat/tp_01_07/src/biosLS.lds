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
            bin/handlers.elf(.init32);
            bin/pic_init.elf(.init32);
            bin/bios.elf(.init32);
            bin/bios.elf(.main);
        } AT >rom                                   /*LMA donde se ubica*/

    .routines 0x00000000 :                          /* rutina del teclado*/
        {
            __ROUTINES_DEST = .;
            __ROUTINES_ORIG = LOADADDR(.routines);
            bin/handlers.elf(.handlers);
            bin/keyboard.elf(.keyboard);
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
            __TABLES_DEST = .;
            __TABLES_ORIG = LOADADDR(.data);
            bin/keyboard.elf(.keyboard_table);
            bin/keyboard.elf(.keyboard_table_init);
        } AT >rom
        __TABLES_LENGTH = SIZEOF(.data);

    .saved_digits_table 0x00210000 :                  /* tabla de digitos guardados*/
        {
            __SAVED_DIGITS_START = .;
            bin/keyboard.elf(.saved_digits_table);
        }
        __SAVED_DIGITS_LENGTH =  SIZEOF(.saved_digits_table);
        __SAVED_DIGITS_END = __SAVED_DIGITS_START + __SAVED_DIGITS_LENGTH;

	.reset 0xFFFFFFF0 :
		{
            *(.reset);
        } AT >reset_bios

}
