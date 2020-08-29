#Script que envia archivos a una ubicación determinada o en su defecto a la 
# cartpeta del proyecto.

#! /usr/bin/bash
FILE=${1:-}
DEF_PATH=${2:-server/}

if [ -z "$FILE" ]
then
    printf "\nDebe ingresar el nombre del archivo!\nModo de uso:\n\n\t./scp_transfer.sh <ARCHIVO> <DIRECTORIO_DESTINO>\n\nDe no especificarse destino, se guarda en la carpeta ~/server.\n\n"
    exit
fi

sshpass -p temppwd scp $FILE ubuntu@192.168.7.2:$DEF_PATH

if [ $? -eq 0 ];
then
    printf "\nArchivo copiado a la BBB en "$DEF_PATH"\n\n"
else
    printf "\n>>>>¡¡Error al copiar el archivo!!.<<<<\n\n"
fi
