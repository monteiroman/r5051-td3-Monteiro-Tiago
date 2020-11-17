#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <math.h>

int main (){
    int fd = 0;
    char datatodriver = 0, key = 0;
    int16_t datafromdriver[6]={0};
    int readSize = 2;
    int16_t X_min = 0; 
    int16_t Y_min = 0; 
    int16_t Z_min = 0; 
    int16_t X_max = 0; 
    int16_t Y_max = 0; 
    int16_t Z_max = 0; 

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

        printf("\n\tData: ----------------------\n");
        printf("\tMag:\n");
        printf("\tX: %+.4d\tY: %+.4d\tZ: %+.4d\n", datafromdriver[3], 
        datafromdriver[4], datafromdriver[5]);

        if(datafromdriver[3] < X_min)
            X_min = datafromdriver[3];
        if(datafromdriver[3] > X_max)
            X_max = datafromdriver[3];
        
        if(datafromdriver[4] < Y_min)
            Y_min = datafromdriver[4];
        if(datafromdriver[4] > Y_max)
            Y_max = datafromdriver[4];
        
        if(datafromdriver[5] < Z_min)
            Z_min = datafromdriver[5];
        if(datafromdriver[5] > Z_max)
            Z_max = datafromdriver[5];

        float midX = ((float)(X_max + X_min) / 2);
        float midY = ((float)(Y_max + Y_min) / 2);
        float midZ = ((float)(Z_max + Z_min) / 2);

        printf("\tHard Offset:\n");
        printf("\tX: %+.4f\tY: %+.4f\tZ: %+.4f\n", midX, midY, midZ);

        readSize = read(fd, &datafromdriver, sizeof(datafromdriver));
        
        usleep(200000);
    }

    return 0;
}
