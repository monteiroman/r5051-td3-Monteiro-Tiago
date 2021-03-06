### Calibración del sensor Magnético.
En los sensores magnéticos aparecen varias fuentes de errores que afectan la medición. En este proyecto solo se afrontó una que es la llamada "Hard Iron" que impedía obtener una medición aceptable para esta instancia siguiendo los leneamientos de [este](https://learn.adafruit.com/adafruit-sensorlab-magnetometer-calibration/simple-magnetic-calibration) y [este](https://github.com/adafruit/Adafruit_SensorLab/blob/master/examples/calibration/mag_hardiron_simplecal/mag_hardiron_simplecal.ino) desarrollo. Esta fuente de error se origina en el chip al momento de ser soldado, por variaciones de tensión y corriente en las pistas de alimentación del circuito o por diferentes motivos fisicos del sensor (por eso Hard-Iron). Las otras fuentes de error existentes que no serán tenidas en cuenta en este proyecto (Soft-iron o inclinación del sensor) pueden ser vistas en [esta nota de aplicación.](https://www.pololu.com/file/0J434/LSM303DLH-compass-app-note.pdf). 

Hay dos formas de calibrar el dispositivo.

* **La primera** es la que se explica en la sección pertinente de [Servidor de archivos HTML](/02_cuat/Readme_docs/server.md).

* **La segunda** es usando el programa de calibración que se encuentra en i2c_driver/test/. Este programa imprime en consola los valores medios de campo magnético medidos por el sensor a medida que se lo va moviendo en todas las direcciones. Luego de obtener los valores, y para un correcto funcionamiento del servidor, se deben colocar los mismos en el archivo "server.cfg" en las líneas X e Y según corresponda con sus signos cambiados.

Se puede ver mas información en [este artículo](https://learn.adafruit.com/lsm303-accelerometer-slash-compass-breakout?view=all) del fabricante del sensor

### Acelerómetro.

Ya que la intención es lograr un compás electrónico básico en esta instancia del proyecto, al acelerómetro solamente se utilizó para informar si la medición del rumbo es válida o no. Si el valor de aceleración de la gravedad para el eje Z es menor a 9m/s<sup>2</sup> se considera que el rumbo es erróneo y se muestra un texto indicando tal caso.

Cabe aclarar que los ejes que se usaron para el cálculo del rumbo son el X e Y y que el rumbo es señalado por X.

#### [Volver al Readme principal](/02_cuat/README.md)