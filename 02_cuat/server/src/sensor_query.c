#include "../inc/sensor_query.h"


void printValues (int16_t *values){
    printf("\n\tHeading & Accel Data: -------------------------------\n");
    // Calculate the angle of the vector y,x
    float X_uTesla = (float)(values[3] + X_MAG_HARDOFFSET);
    float Y_uTesla = (float)(values[4] + Y_MAG_HARDOFFSET);

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

void SIGINT_handler (int signbr) {
    read_sensor = 0;
    if (fd > 0) {
        close(fd);
    }
    printf("\nLSM303 closed\n\n");
    exit(0);
}


int sensor_query (){
    char datatodriver = 0, key = 0;
    int16_t datafromdriver[6]={0};
    int readSize = 2;

    signal(SIGINT, SIGINT_handler);

    printf("Test script.\nOpening driver.\n");
    if((fd = open("/dev/i2c_TM", O_RDWR)) < 0){
        printf("\tCannot open driver. Exit.\n");
        
        return 1;
    }   

    readSize = read(fd, &datafromdriver, sizeof(datafromdriver));

    while(read_sensor){
        if(readSize != sizeof(datafromdriver)){
            printf("\tReaded %d bytes. Error. Exit.\n\tExpected %d\n\n",
                readSize, sizeof(datafromdriver));
            
            return 1;
        }
        printValues(datafromdriver);
        
        readSize = read(fd, &datafromdriver, sizeof(datafromdriver));
        
        usleep(100000);
    }

    return 0;
}
