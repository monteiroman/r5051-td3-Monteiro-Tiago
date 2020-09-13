##################################################################################
#                                                                                #
#              Tiago Monteiro. 1420355  2do cuatrimestre 2020                    #
#                                                                                #
##################################################################################
#   Script que envia archivos a una ubicación determinada o en su defecto a la   # 
#   cartpeta del proyecto.                                                       #
##################################################################################

#! /usr/bin/bash
file=
scpOptions=
inv=false
destPath="/home/debian"
ipAddr="192.168.7.2"
usrName="debian"
pwd="temppwd"
strMsg="Archivo"


#____________________ Functions ____________________#

help(){
    printf "\n\t\t================================================"
    printf "\n\t\t| COPIADOR DE ARCHIVOS PC => BBB // BBB => PC. |"
    printf "\n\t\t================================================\n"
    printf "\nModo de uso:\n\t./scp_transfer.sh [OPCIONES]\n"
    printf "\nOpciones:\n\t-O: Path del archivo o directorio a copiar.\n"
    printf "\t    DEBE DEFINIRSE OBLIGATORIAMENTE.\n"
    printf "\t-D: Path destino al cual se copia el archivo. Por defecto es \"~\".\n"
    printf "\t-R: Copiar un directorio.\n"
    printf "\t-d: Dirección ip a la cual se realiza la conexion.\n"
    printf "\t    Por defecto es 192.168.7.2.\n"
    printf "\t-n: Nombre de usuario. Por defecto es \"ubuntu\".\n"
    printf "\t-p: Password. Por defecto es \"temppwd\".\n"
    printf "\t-i: Sentido inverso, se copia de la BBB a la PC.\n"
    printf "\t    Por defecto se copia de la PC a la BBB.\n"
    printf "\t-h: Ayuda. Muestra este menu.\n\n"
}

transferFile(){
    if [ "$inv" = false ];
    then
    # Copia de la PC a la BBB.
        sshpass -p $pwd scp $scpOptions $file $usrName@$ipAddr:$destPath
    # Chequeo de errores en la copia.
        if [ $? -eq 0 ];
        then
            printf "\n\t>>>> ¡"$strMsg" copiado a la BBB en "\"$destPath\"" con éxito! <<<<\n\n"
        else
            printf "\n\t>>>>¡¡Error al copiar el archivo!!.<<<<\n\n"
        fi
    else
    # Copia de la BBB a la PC.
        sshpass -p $pwd scp $scpOptions $usrName@$ipAddr:$file $destPath 
    # Chequeo de errores en la copia.
        if [ $? -eq 0 ];
        then
            printf "\n\t>>>> ¡"$strMsg" copiado a la PC en "\"$destPath\"" con éxito! <<<<\n\n"
        else
            printf "\n\t>>>>¡¡Error al copiar el archivo!!.<<<<\n\n"
        fi
    fi
}


#____________________ Program flow ____________________#

### Parameters Parser ###
while [ "$1" != "" ]; do
    case $1 in
        -O )    shift
                    file=$1
                    ;;
        -d )    shift
                    ipAddr=$1
                    ;;
        -n )    shift
                    usrName=$1
                    ;;
	    -p )    shift
                    pwd=$1
                    ;;
        -D )    shift
                    destPath=$1
                    ;;
        -R )        scpOptions="-rp"
                    strMsg="Directorio"
                    ;;
        -i )        inv=true
                    ;;
        -h )        help
                    exit
                    ;;
        * )         help
                    exit 1
    esac
    shift
done

if [ -z "$pwd" ] || [ -z "$ipAddr" ] || [ -z "$destPath" ] || [ -z "$usrName" ] || [ -z "$file" ]
then
    help
    exit
fi

### Transfer ###
transferFile


