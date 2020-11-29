#include "../inc/sensor_query.h"


extern int fd;

int sensor_query (){
    int readSize = 0;
    int16_t datafromdriver[6]={0};

    if((fd = open("/dev/i2c_TM", O_RDWR)) < 0){
        printf("\tCannot open driver. Exit.\n");
    
        return -1;
    }   

    readSize = read(fd, &datafromdriver, sizeof(datafromdriver));

    if(readSize != sizeof(datafromdriver)){
        printf("\tReaded %d bytes. Error. Exit.\n\tExpected %d\n\n",
            readSize, sizeof(datafromdriver));
        
        return -1;
    }

    LSM303_values.X_acc = datafromdriver[0];
    LSM303_values.Y_acc = datafromdriver[1];
    LSM303_values.Z_acc = datafromdriver[2];
    LSM303_values.X_mag = datafromdriver[3];
    LSM303_values.Y_mag = datafromdriver[4];
    LSM303_values.Z_mag = datafromdriver[5];

    close(fd);

    usleep(100000);

    
    
    return 0;
}
