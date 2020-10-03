#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>

void printValues (int *values){
    printf("Data: ----------------------\n");
    printf("Accel:\n");
    printf("X: %+.5d\tY: %+.5d\tZ: %+.5d\n", (int16_t)values[0], (int16_t)values[1], 
        (int16_t)values[2]);
    printf("Mag:\n");
    printf("X: %+.3d\t\tY: %+.3d\t\tZ: %+.3d\n", (int16_t)values[3], (int16_t)values[4], 
        (int16_t)values[5]);
}

int main (){
    int fd = 0;
    char datatodriver = 0, key = 0;
    int datafromdriver[6]={0};
    int readSize = 2;

    printf("Test script.\nOpening driver.\n");
    if((fd = open("/dev/i2c_TM", O_RDWR)) < 0){
        printf("\tCannot open driver. Exit.\n");
        
        return 1;
    }   

    readSize = read(fd, &datafromdriver, sizeof(datafromdriver));

    while(1){
        
        printf("\n");

        if(readSize != 24){
            printf("\tReaded %d bytes. Error. Exit.\n", readSize);
            
            return 1;
        }
        printValues(datafromdriver);
        readSize = read(fd, &datafromdriver, sizeof(datafromdriver));
        
        usleep(200000);
    }

    return 0;
}