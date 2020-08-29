#Script que me conecta a la BBB y me deja en la carpeta que me pasan por 
# argumento o en su defecto en la del proyecto "server/".

#! /usr/bin/bash
DEF_PATH=${1:-server/}

sshpass -p temppwd ssh -t ubuntu@192.168.7.2 "cd $DEF_PATH ; bash"
