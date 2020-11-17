#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <math.h>

void printValues (int16_t *values){
    printf("\n\tRaw Data: -------------------------------\n");
    printf("\tAccel:\n");
    printf("\tX: %+.5d\tY: %+.5d\tZ: %+.5d\n", values[0], 
        values[1], values[2]);
    printf("\tMag:\n");
    printf("\tX: %+.4d\tY: %+.4d\tZ: %+.4d\n", values[3], 
        values[4], values[5]);   
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
