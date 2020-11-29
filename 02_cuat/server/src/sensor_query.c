#include "../inc/sensor_query.h"

int16_t datafromdriver[6]={0};

extern int fd;

int sensor_query (){
    int readSize = 0;

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

    
    
    return 0;
}
