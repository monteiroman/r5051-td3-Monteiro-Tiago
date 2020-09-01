
#Script que me conecta a la BBB los valores por defecto son los de las
# variables definidas abajo. Todas esas variables se pueden modificar
# en el momento que se llama al script.

#! /usr/bin/bash
initPath="server/"
ipAddr="192.168.7.2"
usrName="ubuntu"
pwd="temppwd"

#____________________ Functions ____________________#
connect(){
    sshpass -p $pwd ssh -t $usrName@$ipAddr "cd $initPath ; bash"
}

help(){
    printf "\nModo de uso:\n\t./ssh_connect.sh [OPCIONES]\n"
    printf "\nOpciones:\n\t-r: Path de inicio de la conección. Por defecto es ~/server/.\n"
    printf "\t-d: Dirección ip a conectarse. Por defecto es 192.168.7.2.\n"
    printf "\t-n: Nombre de usuario. Por defecto es \"ubuntu\".\n"
    printf "\t-p: Password. Por defecto es \"temppwd\".\n"
    printf "\t-h: Ayuda. Muestra este menu.\n\n"
}

#____________________ Program flow ____________________#

### Parameters Parser ###
while [ "$1" != "" ]; do
    case $1 in
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
                    initPath=$1
                    ;;
        -h )        help
                    exit
                    ;;
        * )         help
                    exit 1
    esac
    shift
done

if [ -z "$pwd" ] || [ -z "$ipAddr" ] || [ -z "$initPath" ] || [ -z "$usrName" ]
then
    help
    exit
fi

### Connection ###
connect
