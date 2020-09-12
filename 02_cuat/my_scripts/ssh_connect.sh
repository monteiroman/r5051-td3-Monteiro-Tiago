##################################################################################
#                                                                                #
#              Tiago Monteiro. 1420355  2do cuatrimestre 2020                    #
#                                                                                #
##################################################################################
#   Script que me conecta a la BBB los valores por defecto son los de las        #
#   variables definidas abajo. Todas esas variables se pueden modificar          #
#   en el momento que se llama al script.                                        #
##################################################################################

#! /usr/bin/bash
initPath="/home/debian"
ipAddr="192.168.7.2"
usrName="debian"
pwd="temppwd"
poweroffFlag=false

#____________________ Functions ____________________#
connect(){
    sshpass -p $pwd ssh -t $usrName@$ipAddr "cd $initPath ; bash"
}

### Para poder usar esta funcion agregar:
#       
#       debian ALL=NOPASSWD: /sbin/halt, /sbin/reboot, /sbin/poweroff
#
# Al archivo:
#       
#       /etc/sudoers
#
# Tener en cuenta que solo será valido para el usuario "debian".
# en caso de usar otro usuario cambiar el nombre.
#
poweroff(){
    sshpass -p $pwd ssh -t $usrName@$ipAddr "sudo poweroff; "
}

help(){
    printf "\nModo de uso:\n\t./ssh_connect.sh [OPCIONES]\n"
    printf "\nOpciones:\n\t-r: Path de inicio de la conección. Por defecto es ~.\n"
    printf "\t-d: Dirección ip a conectarse. Por defecto es 192.168.7.2.\n"
    printf "\t-n: Nombre de usuario. Por defecto es \"ubuntu\".\n"
    printf "\t-p: Password. Por defecto es \"temppwd\".\n"
    printf "\t-x: Apaga la BBB.\n"
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
        -x )        poweroffFlag=true
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

if [ $poweroffFlag = true ]
then
    poweroff
    exit
fi

### Connection ###
connect
