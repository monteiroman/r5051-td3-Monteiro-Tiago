# Tecnicas Digitales III Segundo Cuatrimestre 2020
	
## Tiago Monteiro - Legajo: 142035-5

### Descripción de puntos importantes del proyecto

En este proyecto se programó un driver I2C que comuniqua la placa de desarrollo BeagleBone Black con un sensor a elección del alumno. En particular, en este proyecto de eligió el LSM303DLHC de ST
el cual es un acelerometro y sensor magnético. La hoja de datos del mismo se puede ver [acá](https://cdn-shop.adafruit.com/datasheets/LSM303DLHC.PDF) y la información de la placa donde éste 
está soldado se puede ver [acá.](https://learn.adafruit.com/lsm303-accelerometer-slash-compass-breakout/downloads)

A continuación se intenta explicar cómo está diagramado el proyecto:

### [Driver I2C y Módulo](/02_cuat/Readme_docs/driver.md)

### [Sensor](/02_cuat/Readme_docs/sensor.md)

### [Device Tree](/02_cuat/Readme_docs/device_tree.md)

### [Servidor de archivos HTML](/02_cuat/Readme_docs/sensor.md)

### [Scripts secundarios](/02_cuat/Readme_docs/my_scripts.md)

### [Tareas pendientes](/02_cuat/Readme_docs/sensor.md)

### [Notas](/02_cuat/Readme_docs/sensor.md)

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
