#Script que me conecta a la BBB y me deja en la carpeta del proyecto.

#! /usr/bin/bash
sshpass -p temppwd ssh -t ubuntu@192.168.7.2 'cd server/ ; bash'
