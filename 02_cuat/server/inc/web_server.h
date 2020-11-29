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