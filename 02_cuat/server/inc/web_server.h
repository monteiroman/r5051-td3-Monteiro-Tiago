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
#include <sys/stat.h>

#define MAX_CONN 10 //Nro maximo de conexiones en espera

#define LSM303ACC_G_LSB         0.0039F
#define LSM303ACC_GRAVITY       9.80665F

#define X_MAG_HARDOFFSET        -116
#define Y_MAG_HARDOFFSET        222

#define SHARED_SIZE             4096
#define DATA_MARGIN             128

struct calibValues {
    bool firstCalibFlag;
    int16_t X_min; 
    int16_t Y_min; 
    int16_t Z_min; 
    int16_t X_max; 
    int16_t Y_max; 
    int16_t Z_max; 
};

struct sensorValues {
    int16_t X_acc;
    int16_t Y_acc;
    int16_t Z_acc;
    int16_t X_mag;
    int16_t Y_mag;
    int16_t Z_mag;
};

struct configValues {
    int backlog;                // b
    int current_connections;    // c
    int max_connections;        // m
    int mean_samples;           // s
    int X_HardOffset;           // x
    int Y_HardOffset;           // y
    double sensor_freq;          // f
};

void sensor_query ();
void compassAnswer (char* commBuffer);
void calibAnswer(char* commBuffer, struct calibValues calVal);
void processClient(int s_aux, struct sockaddr_in *pDireccionCliente,
                                                                int puerto);
void SIGINT_handler (int signbr);
void SIGKILL_handler (int signbr);
void SIGCHLD_handler (int signbr);

// Miscelaneous functions
void print_error (char* e_file, char* e_msg);
void print_msg (char* m_file, char* m_msg);
void print_msg_wValue (char* m_file, char* m_msg, long val);
void print_msg_wFloatValue (char* m_file, char* m_msg, float val);

// File dunctions
off_t fsize(const char * path);
unsigned char* readFile(const char* path, size_t* size);
void cfgRead();
