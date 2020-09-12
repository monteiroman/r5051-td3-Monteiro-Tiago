# Tecnicas Digitales III Segundo Cuatrimestre 2020
	
## Tiago Monteiro - Legajo: 142035-5

### -------------------------Scripts------------------------------------
Para el uso de los scripts de este proyecto se debe ejecutar
sudo apt-get install sshpass

### -------------------------Configuración de la BBB para compilación------------
Para configurar la BBB en caso de tener que regenerar la imagen.
    apt update
    apt upgrade
    apt install build-essential linux-header-$(uname -r)
    ln -s /usr/src/linux-headers-$(uname -r)/ /lib/modules/$(uname -r)/build


### -------------------------Device tree------------------------------------
El archivo .dtb es el binario que va en /boot/dtbs/4.19.94-ti-r42.
El archivo .dts es el archivo de texto que tengo que editar.

Para decompilar el .dtb:
dtc -I dtb -O dts am335x-boneblack.dtb -o am335x-boneblack.dts

Para compilar el .dts:
dtc -I dts -O dtb am335x-boneblack.dts -o am335x-boneblack.dtb

Con "ls /proc/device-tree/ocp/" veo si mi device tree está bien hecho.
