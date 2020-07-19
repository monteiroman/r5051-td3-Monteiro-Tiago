#______________________________________________________________________________#
#                            Flags y Definiciones                              #
#______________________________________________________________________________#

# Nombre del archivo binario de salida (.bin).
OUTPUT = bios.bin

# Path archivos fuente (.asm).
SRC_PATH = src

#Path y nombre de los archivos fuente (.asm)
SRC = $(wildcard $(SRC_PATH)/*.asm)

# Path de generación de archivos objeto (.elf).
BIN_PATH = bin

# Path y nombre de los archivos objeto (.elf)
OBJ = $(subst $(SRC_PATH)/,$(BIN_PATH)/,$(SRC:.asm=.elf))

# Archivo de configuracion del bochs (.cfg).
BOCHS_CFG = bochs.cfg

# Compilador
CC = nasm

###	Flags del compilador nasm
# 	|_	"-f elf32": Formato de salida elf 32 bits
#
CFLAGS = -f elf32

# Linker
LD = ld

### Flags del Linker
# 	|_	"-z max-page-size=0x1000": Tamaño maximo de página
# 	|_	"-m elf_i386": Emula un procesador i386
# 	|_	"-T": Usa el script que le paso para linkear
# 	|_	"-Map memory.map": Guarda el mapa de memoria en el archivo memory.map
#
LFLAGS = -z max-page-size=0x1000 -Map memory.map --oformat=binary -m elf_i386 -T


#______________________________________________________________________________#
#                                 Reglas                                       #
#______________________________________________________________________________#

all: $(OUTPUT)
	@echo "=================> ¡COMPILÓ! <================="
	@echo "====> Ejecutando Bochs <===="
	bochs -qf ./$(BOCHS_CFG)
	@echo " "
	@echo "====> Limpiando temporales <===="
	@rm -rf ./*.ini ./*.log
	@echo " "

compile_only: $(OUTPUT)
	@echo " "
	@echo "=================> ¡COMPILÓ! <================="
	@echo " "
	@echo "====> Limpiando temporales <===="
	@rm -rf ./*.ini ./*.log
	@echo " "

$(OUTPUT): $(SRC_PATH)/biosLS.lds $(OBJ)
	@echo "====> Linkeando $^ a $@ <===="
	$(LD) $(LFLAGS) $^ -o $@
	@echo " "

$(BIN_PATH)/%.elf: $(SRC_PATH)/%.asm $(BIN_PATH)
	@echo "====> Compilando $< <===="
	$(CC) $(CFLAGS) $< -o $@
	@echo " "

$(BIN_PATH):
	@mkdir -p $@
	@echo " "

clean:
	@echo "====> Limpiando <===="
	@rm -rf ./*.log ./*.ini ./*.bin ./*.map ./bochsout.txt ./$(BIN_PATH)
