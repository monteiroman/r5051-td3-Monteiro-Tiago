
Para calibrar el dispositivo se debe ejecutar el binario "calibration" que se encuentra en la carpeta test/. Este binario se encarga de buscar el offset de campo del sensor que luego debe ser ingresado en la aplicacion final para calcular correctamente el angulo del compas. Esta calibracion se basa en determinar el offset de campo magnetico que se crea en el chip a la hora de soldarlo, por las pistas de alimentacion del chip o por diferentes motivos fisicos del sensor.

Pagina del fabricante sobre el sensor:
        https://learn.adafruit.com/lsm303-accelerometer-slash-compass-breakout?view=all

Simple magnetic calibration:
        Explicacion: https://learn.adafruit.com/adafruit-sensorlab-magnetometer-calibration/simple-magnetic-calibration
        code: https://github.com/adafruit/Adafruit_SensorLab/blob/master/examples/calibration/mag_hardiron_simplecal/mag_hardiron_simplecal.ino

Application note: https://www.pololu.com/file/0J434/LSM303DLH-compass-app-note.pdf