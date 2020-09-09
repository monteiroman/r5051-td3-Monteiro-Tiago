# Tecnicas Digitales III Segundo Cuatrimestre 2020
	
## Tiago Monteiro - Legajo: 142035-5

Para el uso de los scripts de este proyecto se debe ejecutar
sudo apt-get install sshpass


Para configurar la BBB en caso de cagarla.
apt update
apt upgrade
apt install build-essential linux-header-$(uname -r)
ln -s /usr/src/linux-headers-$(uname -r)/ /lib/modules/$(uname -r)/build


-------------------------Device tree------------------------------------
El archivo .dtb es el binario que va en /boot/dtbs/4.19.94-ti-r42.
El archivo .dts es el archivo de texto que tengo que editar.

Con "ls /proc/device-tree/ocp/" veo si mi device tree está bien hecho.
