#include "../inc/sensor_query.h"

extern int fd;
extern int sock_http;
extern sem_t *data_semaphore;
extern struct sensorValues *sensorValues_data;

int sensor_query (){
    int readSize = 0;
    int16_t datafromdriver[6]={0};

    signal(SIGINT, SIGINT_sensor_handler);

    while(1)
    {    
        if((fd = open("/dev/i2c_TM", O_RDWR)) < 0){
            print_error(__FILE__, "Cannot open driver. Exit.");

            return -1;
        }   

        readSize = read(fd, &datafromdriver, sizeof(datafromdriver));

        if(readSize != sizeof(datafromdriver)){
            printf("\tReaded %d bytes. Error. Exit.\n\tExpected %d\n\n",
                readSize, sizeof(datafromdriver));

            return -1;
        }

        close(fd);

        sem_wait(data_semaphore);
        sensorValues_data->X_acc = datafromdriver[0];
        sensorValues_data->Y_acc = datafromdriver[1];
        sensorValues_data->Z_acc = datafromdriver[2];
        sensorValues_data->X_mag = datafromdriver[3];
        sensorValues_data->Y_mag = datafromdriver[4];
        sensorValues_data->Z_mag = datafromdriver[5];
        sem_post(data_semaphore);
    
        usleep(100000);
    }
    return 0;
}

void SIGINT_sensor_handler (int signbr) {
    close(sock_http);
    
    if (fd > 0) {
        close(fd);
    }
    printf("\nLSM303 closed\n\n");
    exit(0);
}
