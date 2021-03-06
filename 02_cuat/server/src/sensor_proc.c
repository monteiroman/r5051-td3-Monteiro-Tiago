#include "../inc/sensor_proc.h"

int fd;
extern int sock_http;
extern sem_t *data_semaphore, *cfg_semaphore;
extern struct sensorValues *sensorValues_data;
extern struct configValues *configValues_data;
size_t mave_array_sz = 0;
float *mave_array = NULL;
extern bool exit_flag;

void sensor_query (){
    int readSize = 0, mave_samples = 0, idx = 0;
    int16_t datafromdriver[6]={0};
    float sensor_period = 0;
    bool mave_change = false;
    float xAcc_prom = 0, yAcc_prom = 0, zAcc_prom = 0;
    float xMag_prom = 0, yMag_prom = 0, zMag_prom = 0;

    signal(SIGINT, SIGINT_sensor_handler);

// -------> Get moving average samples value <-------
    sem_wait(cfg_semaphore);
    if(configValues_data->mean_samples < 1){
        print_msg(__FILE__, 
          "Please check Moving Average samples value. Must be greater than 0.");    
        mave_samples = 5;    
    }else{
        mave_samples = configValues_data->mean_samples;
    }
    sem_post(cfg_semaphore);

    // Alloc memory for moving average filter.
    mave_array = calloc((size_t) 6*mave_samples, sizeof(float));
    mave_array_sz = (size_t) (6*mave_samples*sizeof(float));

// -------> Sensor logic <-------
    while(!exit_flag)
    {   
        sem_wait(cfg_semaphore);
        sensor_period = configValues_data->sensor_period;

        if(configValues_data->mean_samples < 1){
            print_msg(__FILE__, 
          "Please check Moving Average samples value. Must be greater than 0.");    
            mave_samples = 5; 
            mave_change = true;
        }else{
            if(mave_samples != configValues_data->mean_samples){
                mave_samples = configValues_data->mean_samples;
                mave_change = true;
                print_msg_wValue(__FILE__, 
                        "New value of samples set (%d samples).", mave_samples);

            }
        }
        sem_post(cfg_semaphore); 

        // -------> Driver descriptor <-------
        int error_count = 0;
        while((fd = open("/dev/i2c_TM", O_RDWR)) < 0){
            error_count++;
            print_msg_wValue(__FILE__, "Trying reconection %d/3...", 
                                                                error_count);

            if(error_count == 3){                                                    
                print_error(__FILE__, 
                                    "Cannot open driver, driver process exit");

                exit(1);
            }
            usleep(2 * SECOND);
        }   

        readSize = read(fd, &datafromdriver, sizeof(datafromdriver));

        close(fd);

        if(readSize != sizeof(datafromdriver)){
            printf("[ERROR]  | Readed %d bytes, expected %d bytes.\n",
                                            readSize, sizeof(datafromdriver));
            
            print_error(__FILE__,"Driver process exit with error"); 

            exit(1);
        }

        // -------> Moving average logic <-------
        if(mave_change){
            mave_change = false;
            // Realloc memory for moving average filter.
            free(mave_array);
            mave_array = calloc((size_t) 6*mave_samples, sizeof(float));
        }

        idx ++;
        if (idx >= mave_samples){
            idx = 0;
        }

        xAcc_prom = 0;
        yAcc_prom = 0;
        zAcc_prom = 0;
        xMag_prom = 0;
        yMag_prom = 0;
        zMag_prom = 0;
        
        mave_array[6*idx + 0] = (float) datafromdriver[0];
        mave_array[6*idx + 1] = (float) datafromdriver[1];
        mave_array[6*idx + 2] = (float) datafromdriver[2];
        mave_array[6*idx + 3] = (float) datafromdriver[3];
        mave_array[6*idx + 4] = (float) datafromdriver[4];
        mave_array[6*idx + 5] = (float) datafromdriver[5];

        for (int i=0; i<=mave_samples; i++){
            xAcc_prom += mave_array[6*i + 0];
            yAcc_prom += mave_array[6*i + 1];
            zAcc_prom += mave_array[6*i + 2];
            xMag_prom += mave_array[6*i + 3];
            yMag_prom += mave_array[6*i + 4];
            zMag_prom += mave_array[6*i + 5];
        }

        xAcc_prom /= mave_samples; 
        yAcc_prom /= mave_samples; 
        zAcc_prom /= mave_samples; 
        xMag_prom /= mave_samples; 
        yMag_prom /= mave_samples; 
        zMag_prom /= mave_samples;

        // -------> Return values <-------
        // Copy values to shared memory.
        sem_wait(data_semaphore);
        sensorValues_data->X_acc = (int16_t)floor(xAcc_prom);
        sensorValues_data->Y_acc = (int16_t)floor(yAcc_prom);
        sensorValues_data->Z_acc = (int16_t)floor(zAcc_prom);
        sensorValues_data->X_mag = (int16_t)floor(xMag_prom);
        sensorValues_data->Y_mag = (int16_t)floor(yMag_prom);
        sensorValues_data->Z_mag = (int16_t)floor(zMag_prom);
        sem_post(data_semaphore);
    
        usleep((useconds_t) (sensor_period * SECOND));
    }
    close(sock_http);

    if(mave_array != NULL){
        bzero(mave_array, mave_array_sz);
        free(mave_array);    
    }
    
    if(fd > 0) {
        close(fd);
    }
}

void SIGINT_sensor_handler (int signbr) {
    exit_flag = true;
}
