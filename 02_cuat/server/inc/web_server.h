#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <math.h>
#include <signal.h>
#include <stdbool.h>

#define MAX_CONN 10 //Nro maximo de conexiones en espera

#define LSM303ACC_G_LSB         0.0039F
#define LSM303ACC_GRAVITY       9.80665F

#define X_MAG_HARDOFFSET        -116
#define Y_MAG_HARDOFFSET        222

struct calibValues {
    int16_t X_min; 
    int16_t Y_min; 
    int16_t Z_min; 
    int16_t X_max; 
    int16_t Y_max; 
    int16_t Z_max; 
} calVal;

struct sensorValues {
    int16_t X_acc;
    int16_t Y_acc;
    int16_t Z_acc;
    int16_t X_mag;
    int16_t Y_mag;
    int16_t Z_mag;
} LSM303_values;
