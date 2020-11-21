#include "../inc/sensor_query.h"

extern float LSM303_data[];
extern int fd;

int sensor_query (){
    char datatodriver = 0, key = 0;
    int16_t datafromdriver[6]={0};
    int readSize = 2;

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

    close(fd);

    usleep(100000);


    // Calculate the angle of the vector y,x
    float X_uTesla = (float)(datafromdriver[3] + X_MAG_HARDOFFSET);
    float Y_uTesla = (float)(datafromdriver[4] + Y_MAG_HARDOFFSET);

    LSM303_data[0] = ((float)(atan2(Y_uTesla, X_uTesla) * 180) / M_PI);

    // Normalize to 0-360
    if (LSM303_data[0] < 0){
        LSM303_data[0] = 360 + LSM303_data[0];
    }

    printf("\n\tSensor heading: %.2f°\n", LSM303_data[0]);

    LSM303_data[1] = (float)datafromdriver[0] * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    LSM303_data[2] = (float)datafromdriver[1] * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    LSM303_data[3] = (float)datafromdriver[2] * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    
    return 0;
}
