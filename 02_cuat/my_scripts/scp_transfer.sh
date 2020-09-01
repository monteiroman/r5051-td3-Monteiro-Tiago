#Script que envia archivos a una ubicación determinada o en su defecto a la 
# cartpeta del proyecto.

#! /usr/bin/bash
file=
scpOptions=
destPath="server/"
ipAddr="192.168.7.2"
usrName="ubuntu"
pwd="temppwd"
strMsg="Archivo"


#____________________ Functions ____________________#

help(){
    printf "\nModo de uso:\n\t./scp_transfer.sh [OPCIONES]\n"
    printf "\nOpciones:\n\t-f: Archivo a copiar DEBE DEFINIRSE OBLIGATORIAMENTE.\n"
    printf "\t-r: Path al cual se copia el archivo. Por defecto es ~/server/.\n"
    printf "\t-d: Dirección ip a la cual se copia el archivo. Por defecto es 192.168.7.2.\n"
    printf "\t-n: Nombre de usuario. Por defecto es \"ubuntu\".\n"
    printf "\t-p: Password. Por defecto es \"temppwd\".\n"
    printf "\t-h: Ayuda. Muestra este menu.\n\n"
}

transferFile(){
    sshpass -p $pwd scp $scpOptions $file $usrName@$ipAddr:$destPath

    if [ $? -eq 0 ];
    then
        printf "\n\t>>>> ¡"$strMsg" copiado a la BBB en "\"$destPath\"" con éxito! <<<<\n\n"
    else
        printf "\n\t>>>>¡¡Error al copiar el archivo!!.<<<<\n\n"
    fi
}


#____________________ Program flow ____________________#

### Parameters Parser ###
while [ "$1" != "" ]; do
    case $1 in
        -f )    shift
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
        -r )    shift
                    destPath=$1
                    ;;
        -R )        scpOptions="-rp"
                    strMsg="Directorio"
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


