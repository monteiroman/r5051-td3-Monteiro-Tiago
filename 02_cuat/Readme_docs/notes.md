### NOTAS
#### Configuración de la BBB para compilación local
Para configurar la BBB para compilar en forma local en caso de tener que regenerar la imagen.

    $ sudo apt update
    $ sudo apt upgrade
    $ sudo apt install build-essential linux-headers-$(uname -r)
    $ sudo ln -s /usr/src/linux-headers-$(uname -r)/ /lib/modules/$(uname -r)/build

#### Como ver mi sensor con el Device Tree original
En este proyecto se utilizó el LSM303 que tiene las direcciones 0x19 y 0x1E del I2C-2
Esto se puede ver con:

    sudo i2cdetect -y -r 2

Cuando se encuentra presente el driver del Linux, es decir, con el device tree original.

#### [Volver al Readme principal](/02_cuat/README.md)