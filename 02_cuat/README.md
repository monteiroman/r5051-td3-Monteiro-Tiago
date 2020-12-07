# Tecnicas Digitales III Segundo Cuatrimestre 2020
	
## Tiago Monteiro - Legajo: 142035-5

<div align="center">

<img src="/02_cuat/Readme_docs/img/server.gif" width="30%"></img>
</div>

## Para compilar y correr el proyecto
        
        cd 02_cuat
        make
        make run_server

### Descripción de puntos importantes del proyecto

En este proyecto se programó un driver I2C que comuniqua la placa de desarrollo BeagleBone Black con un sensor a elección del alumno. En particular, en este proyecto de eligió el LSM303DLHC de ST,
se trata de un acelerómetro y sensor magnético de tres ejes. La **hoja de datos** del mismo se puede ver [**acá**](https://cdn-shop.adafruit.com/datasheets/LSM303DLHC.PDF) y la información de la placa donde éste 
está soldado se puede ver [**acá.**](https://learn.adafruit.com/lsm303-accelerometer-slash-compass-breakout/downloads)

A continuación se intenta explicar cómo está diagramado el proyecto:

### [Driver I2C y Módulo](/02_cuat/Readme_docs/driver.md)

### [Sensor](/02_cuat/Readme_docs/sensor.md)

### [Device Tree](/02_cuat/Readme_docs/device_tree.md)

### [Servidor de archivos HTML](/02_cuat/Readme_docs/server.md)

### [Scripts secundarios](/02_cuat/Readme_docs/my_scripts.md)

### [Notas](/02_cuat/Readme_docs/notes.md)
