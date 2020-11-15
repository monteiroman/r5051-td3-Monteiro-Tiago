#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <math.h>

#define PI 3.141592654

void printValues (int16_t *values){
    printf("\tData: ----------------------\n");
    printf("\tAccel:\n");
    printf("\tX: %+.5d\tY: %+.5d\tZ: %+.5d\n", values[0], 
        values[1], values[2]);
    printf("\tMag:\n");
    printf("\tX: %+.4d\tY: %+.4d\tZ: %+.4d\n", values[3], 
        values[4], values[5]);

    // Calculate the angle of the vector y,x
    float heading = (float)((float)(atan2((double)values[4],(double)values[3]) * 180) / PI);

    // Normalize to 0-360
    if (heading < 0){
        heading = 360 + heading;
    }

    printf("\n\tSensor heading: %.2f°\n", heading);
    
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
        
        printf("\n");

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