#include "../inc/web_server_reply.h"

extern sem_t *data_semaphore, *calib_semaphore, *cfg_semaphore;
extern struct sensorValues *sensorValues_data;
extern struct calibValues *calibration_data;
extern struct configValues *configValues_data;
extern bool config_flag;

void processClient(int s_aux, struct sockaddr_in *pDireccionCliente, int puerto){
    char commBuffer[8192];
    char ipAddr[20];
    int Port;
    int indiceEntrada;
    char *sensorOption,*method;
    int tempValida = 0;
    struct sensorValues LSM303_values;
    bool is_favicon = false;
  
    strcpy(ipAddr, inet_ntoa(pDireccionCliente->sin_addr));
    Port = ntohs(pDireccionCliente->sin_port);
    
    // Client message.
    if (recv(s_aux, commBuffer, sizeof(commBuffer), 0) == -1){
        print_error(__FILE__, "recv() fails");
        exit(1);
    }
  
    // Obtain requested method and file.
    method = strtok(commBuffer, " \t\r\n");    // GET or POST
    sensorOption   = strtok(NULL, " \t");      // File name (/compass or /calib)
    
    // Check if it is a GET method.
    if (memcmp(method, "GET", 5) == 0){
        if(memcmp(sensorOption, "/index", 6) == 0){
            indexAnswer(commBuffer);
        }else if(memcmp(sensorOption, "/compass", 8) == 0){
            compassAnswer(commBuffer);
        }else if(memcmp(sensorOption, "/calib", 6) == 0){
            calibAnswer(commBuffer);
        }else if(memcmp(sensorOption, "/data_compass", 13) == 0){
            compassDataAnswer(commBuffer);
        }else if(memcmp(sensorOption, "/data_calib", 11) == 0){
            calibDataAnswer(commBuffer);
        }else if(memcmp(sensorOption, "/favicon.ico", 12) == 0){
            faviconAnswer(commBuffer);
            is_favicon = true;
        }
    }
   
    // Reply to client.
    if (send(s_aux, commBuffer, strlen(commBuffer), 0) == -1){
        print_error(__FILE__, "send() fails");
        exit(1);
    }

    if(is_favicon){
        size_t _size = fsize(FAVICON_PATH);
        int fp = open(FAVICON_PATH, O_RDONLY);

        if(sendfile(s_aux, fp, NULL, _size) == -1){
            print_error(__FILE__, "sendfile() fails");
            exit(1);
        }
        close(fp);
    } 
    // Close actual client connection.
    close(s_aux);
}

void indexAnswer(char* commBuffer){
    char *HTML;
    size_t html_size = 0;

    HTML = readFile(INDEX_PATH, &html_size);
            
    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Length: %d\n"
            "Content-Type: text/html; charset=utf-8\n"
            "Connection: Closed\n\n%s",
            html_size, HTML);
    free(HTML);
}

void faviconAnswer(char* commBuffer){
    size_t html_size = fsize(FAVICON_PATH);

    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Length: %d\n"
            "Content-Type: image/x-icon\n"
            "Connection: Closed\n\n",
            html_size);
}

void compassAnswer(char* commBuffer){
    char *HTML;
    size_t html_size = 0;

    HTML = readFile(COMPASS_PATH, &html_size);
            
    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Length: %d\n"
            "Content-Type: text/html; charset=utf-8\n"
            "Connection: Closed\n\n%s",
            html_size, HTML);
    free(HTML);
}

void compassDataAnswer(char* commBuffer){
    int xMagHardoffset = 0, yMagHardoffset = 0; 
    float heading = 0;
    float LSM303_accel_x = 0;
    float LSM303_accel_y = 0;
    float LSM303_accel_z = 0;
    char encabezadoHTML[4096];
    char *HTML;
    int not_valid_heading;
    struct sensorValues LSM303_values;
    size_t html_size = 0;

// -------> Compass logic. <-------
    // Set callibration first time to true.
    sem_wait(calib_semaphore);
    calibration_data->firstCalibFlag = true;
    sem_post(calib_semaphore);
    
    // Wait semaphore and get sensor data. 
    sem_wait(data_semaphore);
    LSM303_values.X_acc = sensorValues_data->X_acc;
    LSM303_values.Y_acc = sensorValues_data->Y_acc;
    LSM303_values.Z_acc = sensorValues_data->Z_acc;
    LSM303_values.X_mag = sensorValues_data->X_mag;
    LSM303_values.Y_mag = sensorValues_data->Y_mag;
    LSM303_values.Z_mag = sensorValues_data->Z_mag;
    sem_post(data_semaphore);

    // Obtain ofset values.
    sem_wait(cfg_semaphore);
    xMagHardoffset = configValues_data->X_HardOffset;
    yMagHardoffset = configValues_data->Y_HardOffset;
    sem_post(cfg_semaphore);

    // Calculate the angle of the vector y,x
    float X_uTesla = (float)(LSM303_values.X_mag + xMagHardoffset);
    float Y_uTesla = (float)(LSM303_values.Y_mag + yMagHardoffset);

    heading = ((float)(atan2(Y_uTesla, X_uTesla) * 180) / M_PI);

    // Normalize to 0-360
    if (heading < 0){
        heading = 360 + heading;
    }

    LSM303_accel_x = (float)LSM303_values.X_acc * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    LSM303_accel_y = (float)LSM303_values.Y_acc * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    LSM303_accel_z = (float)LSM303_values.Z_acc * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    
    // If sensor is not straight the heading measure is wrong.
    not_valid_heading = (LSM303_accel_z < STRAIGHT_SENSOR_G) ? 1 : 0; 

    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Type: text/event-stream\n"
            "Cache-Control: no-cache\n"
            "Connection: keep-alive\n"
            "Retry: 1000\n"
            "\n"
            "data: %.2f %.2f %.2f %.2f %d\n\n",
            heading, LSM303_accel_x, LSM303_accel_y, LSM303_accel_z, 
            not_valid_heading);
}

void calibAnswer(char* commBuffer){
    char *HTML;
    size_t html_size = 0;

    HTML = readFile(CALIBRATION_PATH, &html_size);
            
    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Length: %d\n"
            "Content-Type: text/html; charset=utf-8\n"
            "Connection: Closed\n\n%s",
            html_size, HTML);
    free(HTML);
}

void calibDataAnswer(char* commBuffer){
    char encabezadoHTML[4096];
    char *HTML;
    bool first_time;
    struct sensorValues LSM303_values;
    size_t html_size = 0;
    struct calibValues calVal;

// -------> Calibration logic. <-------
    // Wait semaphore and get sensor data. 
    sem_wait(data_semaphore);
    LSM303_values.X_acc = sensorValues_data->X_acc;
    LSM303_values.Y_acc = sensorValues_data->Y_acc;
    LSM303_values.Z_acc = sensorValues_data->Z_acc;
    LSM303_values.X_mag = sensorValues_data->X_mag;
    LSM303_values.Y_mag = sensorValues_data->Y_mag;
    LSM303_values.Z_mag = sensorValues_data->Z_mag;
    sem_post(data_semaphore);

    // Wait semaphore and get calibration data.
    sem_wait(calib_semaphore);
    first_time = calibration_data->firstCalibFlag;

    if(first_time){                     // If it is the first time on the  
        calibration_data->X_min = 0;    //  callibration page it must be set 
        calibration_data->X_max = 0;    //  to zero.
        calibration_data->Y_min = 0;
        calibration_data->Y_max = 0;
        calibration_data->Z_min = 0;
        calibration_data->Z_max = 0;
    }
    
    calVal.X_min = calibration_data->X_min;
    calVal.X_max = calibration_data->X_max;
    calVal.Y_min = calibration_data->Y_min;
    calVal.Y_max = calibration_data->Y_max;
    calVal.Z_min = calibration_data->Z_min;
    calVal.Z_max = calibration_data->Z_max;
    
    calibration_data->firstCalibFlag = false;
    sem_post(calib_semaphore);

    // Min and max values.
    if(LSM303_values.X_mag < calVal.X_min)
        calVal.X_min = LSM303_values.X_mag;
    if(LSM303_values.X_mag > calVal.X_max)
        calVal.X_max = LSM303_values.X_mag;
    
    if(LSM303_values.Y_mag < calVal.Y_min)
        calVal.Y_min = LSM303_values.Y_mag;
    if(LSM303_values.Y_mag > calVal.Y_max)
        calVal.Y_max = LSM303_values.Y_mag;
    
    if(LSM303_values.Z_mag < calVal.Z_min)
        calVal.Z_min = LSM303_values.Z_mag;
    if(LSM303_values.Z_mag > calVal.Z_max)
        calVal.Z_max = LSM303_values.Z_mag;

    float midX = ((float)(calVal.X_max + calVal.X_min) / 2);
    float midY = ((float)(calVal.Y_max + calVal.Y_min) / 2);
    float midZ = ((float)(calVal.Z_max + calVal.Z_min) / 2);

    // Store calibration data in shared mem.
    sem_wait(calib_semaphore);
    calibration_data->X_min = calVal.X_min;
    calibration_data->X_max = calVal.X_max;
    calibration_data->Y_min = calVal.Y_min;
    calibration_data->Y_max = calVal.Y_max;
    calibration_data->Z_min = calVal.Z_min;
    calibration_data->Z_max = calVal.Z_max;
    sem_post(calib_semaphore);

    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Type: text/event-stream\n"
            "Cache-Control: no-cache\n"
            "Connection: keep-alive\n"
            "Retry: 1000\n"
            "\n"
            "data: %+.0f %+.0f %+.0f\n\n",
            midX, midY, midZ);
}
