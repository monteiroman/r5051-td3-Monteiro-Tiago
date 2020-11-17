#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <math.h>

#define LSM303MAG_GAUSS_LSB_XY  1100
#define GAUSS_TO_MICROTESLA     100

#define LSM303ACC_G_LSB         0.0039F
#define LSM303ACC_SHIFT         6
#define LSM303ACC_GRAVITY       9.80665F

#define X_MAG_HARDOFFSET        -116
#define Y_MAG_HARDOFFSET        222 


void printValues (int16_t *values){
    printf("\n\tRaw Data: ----------------------\n");
    printf("\tAccel:\n");
    printf("\tX: %+.5d\tY: %+.5d\tZ: %+.5d\n", values[0], 
        values[1], values[2]);
    printf("\tMag:\n");
    printf("\tX: %+.4d\tY: %+.4d\tZ: %+.4d\n", values[3], 
        values[4], values[5]);

    // Calculate the angle of the vector y,x
    float X_uTesla = (float)(values[3] + X_MAG_HARDOFFSET);// / LSM303MAG_GAUSS_LSB_XY * GAUSS_TO_MICROTESLA;
    float Y_uTesla = (float)(values[4] + Y_MAG_HARDOFFSET);// / LSM303MAG_GAUSS_LSB_XY * GAUSS_TO_MICROTESLA;

    float heading = ((float)(atan2(Y_uTesla, X_uTesla) * 180) / M_PI);

    // Normalize to 0-360
    if (heading < 0){
        heading = 360 + heading;
    }

    printf("\n\tSensor heading: %.2f°\n", heading);

    float X_Gs = (float)values[0] * LSM303ACC_G_LSB * LSM303ACC_GRAVITY;
    float Y_Gs = (float)values[1] * LSM303ACC_G_LSB * LSM303ACC_GRAVITY;
    float Z_Gs = (float)values[2] * LSM303ACC_G_LSB * LSM303ACC_GRAVITY;

    printf("\n\tAcceleration:\n\tX: %.2f m/s2\tY: %.2f m/s2\tZ: %.2f m/s2\n", 
                                                X_Gs, Y_Gs, Z_Gs);    
}

int main (){
    int fd = 0;
    char datatodriver = 0, key = 0;
    int16_t datafromdriver[6]={0};
    int readSize = 2;

    printf("Test script.\nOpening driver.\n");
    if((fd = open("/dev/i2c_TM", O_RDWR)) < 0){
        printf("\tCannot open driver. Exit.\n");
        
        return 1;
    }   

    readSize = read(fd, &datafromdriver, sizeof(datafromdriver));

    while(1){
        if(readSize != sizeof(datafromdriver)){
            printf("\tReaded %d bytes. Error. Exit.\n\tExpected %d\n\n",
                readSize, sizeof(datafromdriver));
            
            return 1;
        }
        printValues(datafromdriver);
        
        readSize = read(fd, &datafromdriver, sizeof(datafromdriver));
        
        usleep(200000);
    }

    return 0;
}