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
            *(.init);                               /*Seccion que voy a copiar*/
        } AT >rom                                   /*LMA donde se ubica*/

    .functions 0x00000000 :
        {   __COPY_DEST1 = .;
            __COPY_ORIG = LOADADDR(.functions);
            *(.copy);
        } AT >rom
        __COPY_LENGTH = SIZEOF(.functions);

	.reset 0xFFFFFFF0 :
		{
            *(.reset);
        } AT >reset_bios

    __COPY_DEST2 = 0x00100000;
    __COPY_DEST3 = 0x00200000;
}
