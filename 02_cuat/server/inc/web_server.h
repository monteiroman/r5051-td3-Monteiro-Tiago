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
#include <sys/wait.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <semaphore.h>

#define MAX_CONN 10 //Nro maximo de conexiones en espera

#define LSM303ACC_G_LSB         0.0039F
#define LSM303ACC_GRAVITY       9.80665F

#define X_MAG_HARDOFFSET        -116
#define Y_MAG_HARDOFFSET        222

#define SHARED_SIZE             4096
#define STRAIGHT_SENSOR_G       9

struct calibValues {
    bool firstCalibFlag;
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
};

int sensor_query ();
void compassAnswer (char* commBuffer);
void calibAnswer(char* commBuffer, struct calibValues calVal);
void setCalToZero();
void processClient(int s_aux, struct sockaddr_in *pDireccionCliente,
                                                                int puerto);
void SIGINT_handler (int signbr);
void SIGCHLD_handler (int signbr);

// Miscelaneous functions
void print_error (char* e_file, char* e_msg);
