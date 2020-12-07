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
#include <sys/select.h>
#include <sys/sendfile.h>


#define MAX_CONN 10 //Nro maximo de conexiones en espera

#define LSM303ACC_G_LSB         0.0039F
#define LSM303ACC_GRAVITY       9.80665F

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
    int backlog;                // in conf file: b
    int current_connections;    // in conf file: c
    int max_connections;        // in conf file: m
    int mean_samples;           // in conf file: s
    int X_HardOffset;           // in conf file: x
    int Y_HardOffset;           // in conf file: y
    float sensor_period;        // in conf file: f 
};

// System functions
void sensor_query ();
void compassAnswer (char* commBuffer);
void calibAnswer(char* commBuffer);
void processClient(int s_aux, struct sockaddr_in *pDireccionCliente,
                                                                int puerto);

// Server reply
void compassDataAnswer(char* commBuffer);
void calibDataAnswer(char* commBuffer);
void indexAnswer(char* commBuffer);
void faviconAnswer(char* commBuffer);
void error404(char* commBuffer);

// Signal handlers.
void SIGINT_handler (int signbr);
void SIGUSR1_handler (int signbr);
void SIGCHLD_handler (int signbr);

// Miscelaneous functions.
void print_error (char* e_file, char* e_msg);
void print_msg (char* m_file, char* m_msg);
void print_msg_wValue (char* m_file, char* m_msg, long val);
void print_msg_wFloatValue (char* m_file, char* m_msg, float val);

// Config dunctions.
off_t fsize(const char * path);
unsigned char* readFile(const char* path, size_t* size);
int readAndUpdateCfg();
int updateConfig();
unsigned char* readBinFile(const char* path, size_t* size);


