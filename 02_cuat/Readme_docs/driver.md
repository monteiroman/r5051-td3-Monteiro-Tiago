### Driver

Se realizó un driver de caracteres que está encargado del manejo tanto del Bus I2C como del platform driver. Toda la implelmentación se realzó en la placa de desarrollor BeagleBone Black de Texas instruments siguiendo el siguiente [manual.](https://www.ti.com/lit/ug/spruh73q/spruh73q.pdf)

Los archivos que complementan la parte de driver se encuentran en la carpeta [**/02_cuat/i2c_driver.**](/02_cuat/i2c_driver)

* La carpeta /test contiene programas en c que se utilizaron para probar el sensor y clibrar el mismo mientras se estaba realizando el servidor.
* La carpeta /src tiene el código en c del driver.
* La carpeta /inc contiene las definociones y headers del driver.

Durante el desarrollo del TP también fueron de ayuda las siguientes páginas:
    
* https://manned.org/
    
* https://www.fsl.cs.sunysb.edu/kernel-api/

#### [Volver al Readme principal](/02_cuat/README.md)
