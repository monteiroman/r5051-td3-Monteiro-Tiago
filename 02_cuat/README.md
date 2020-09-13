# Tecnicas Digitales III Segundo Cuatrimestre 2020
	
## Tiago Monteiro - Legajo: 142035-5

### Scripts
Para el uso de los scripts de este proyecto se debe ejecutar
sudo apt-get install sshpass.
Estos scripts se utilizaron para hacer mas simple la conección a la BBB durante los días de trabajo.

* **scp_transfer**: Se encarga de pasar archivos desde y hacia la BBB con valores por defecto que permiten hacer el trabajo mas fácil.

* **ssh_connect**: Se encarga de conectar la PC a la BBB con valores por defecto, también puede apagar la BBB.

### Configuración de la BBB para compilación
Para configurar la BBB en caso de tener que regenerar la imagen.

    $ sudo apt update
    $ sudo apt upgrade
    $ sudo apt install build-essential linux-header-$(uname -r)
    $ sudo ln -s /usr/src/linux-headers-$(uname -r)/ /lib/modules/$(uname -r)/build


### Device tree
El archivo **.dtb** es el binario que va en **/boot/dtbs/4.19.94-ti-r42**.
El archivo **.dts** es el archivo de texto que tengo que editar. En él hay que cambiar el 

* Para decompilar el .dtb:
    
        dtc -I dtb -O dts am335x-boneblack.dtb -o am335x-boneblack.dts

* Para compilar el .dts:
    
        dtc -I dts -O dtb am335x-boneblack.dts -o am335x-boneblack.dtb

Con **"ls /proc/device-tree/ocp/"** veo si mi device tree está bien hecho.


#### Para hacer andar el device tree

Editar **/boot/uEnv.txt**

Se comenta la siguiente línea:

    #enable_uboot_overlays=1

Se eliminan los comentarios de las siguientes líneas:

    disable_uboot_overlay_emmc=1
    disable_uboot_overlay_video=1
    disable_uboot_overlay_audio=1
    disable_uboot_overlay_wireless=1
    disable_uboot_overlay_adc=1