#include "../inc/web_server.h"

int sock_http, backlog_aux;
void *sharedMemPtr = (void *) 0;
sem_t *data_semaphore, *calib_semaphore, *cfg_semaphore;
struct sensorValues *sensorValues_data;
struct calibValues *calibration_data;
struct configValues *configValues_data;
bool config_flag = false, max_connected = true, exit_flag = false;

int main(int argc, char *argv[]){
    struct sockaddr_in datosServidor;
    socklen_t longDirec;
    pid_t server_pid, httpClient_pid, sensor_query_pid;
    int sharedMemId, sret;
    fd_set readfds;
    struct timeval timeout;

// -------> Help <-------
    if (argc != 2){
        printf("\n\nLinea de comandos: webserver Puerto\n\n");
        
        exit(1);
    }

    server_pid = getpid();
    print_msg_wValue(__FILE__, "Server pid: %d", (long)server_pid);

// -------> Signal handlers <-------
    signal(SIGINT, SIGINT_handler);
    signal(SIGCHLD, SIGCHLD_handler);
    signal(SIGUSR1, SIGUSR1_handler);

// -------> Shared memory <-------
    // Get shmem
    sharedMemId = shmget( (key_t)1234, SHARED_SIZE, 0666 | IPC_CREAT);
    if (sharedMemId == -1) {
        print_error(__FILE__, "shmget failed");
        
        return -1;
    }
    // Attach shmem
    sharedMemPtr = shmat(sharedMemId, (void *)0, 0);
    if (sharedMemPtr == (void *)-1) {
        print_error(__FILE__, "shmat failed");
        
        return -1;
    }
    print_msg_wValue(__FILE__, "Shared memory attached at: %p", 
                                                        (long)sharedMemPtr);
    
    // Point the struct to the corresponding shared memory.
    sensorValues_data = (struct sensorValues *)sharedMemPtr;
    calibration_data = (struct calibValues *)
                (sharedMemPtr + sizeof(struct sensorValues) + DATA_MARGIN);
    configValues_data = (struct configValues *) 
                (calibration_data + sizeof(struct calibValues) + DATA_MARGIN);

// -------> Semaphores <-------
    sem_unlink ("data_semaphore");
    data_semaphore = sem_open ("data_semaphore", O_CREAT | O_EXCL, 0644, 1);
    if (data_semaphore < 0){
        shmdt(sharedMemPtr);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        print_error(__FILE__, "Can't create data semaphore");

        return -1;
    }

    sem_unlink ("calib_semaphore");
    calib_semaphore = sem_open ("calib_semaphore", O_CREAT | O_EXCL, 0644, 1);
    if (calib_semaphore < 0){
        shmdt(sharedMemPtr);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        sem_unlink ("calib_semaphore");
        sem_close(calib_semaphore);
        print_error(__FILE__, "Can't create calibration semaphore");

        return -1;
    }

    sem_unlink ("cfg_semaphore");
    cfg_semaphore = sem_open ("cfg_semaphore", O_CREAT | O_EXCL, 0644, 1);
    if (cfg_semaphore < 0){
        shmdt(sharedMemPtr);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        sem_unlink ("calib_semaphore");
        sem_close(calib_semaphore);
        sem_unlink ("cfg_semaphore");
        sem_close(cfg_semaphore);
        print_error(__FILE__, "Can't create calibration semaphore");

        return -1;
    }

// -------> Set calibration data to zero <-------
    sem_wait(calib_semaphore);
    calibration_data->X_min = 0;
    calibration_data->Y_min = 0;
    calibration_data->Z_min = 0;
    calibration_data->X_max = 0;
    calibration_data->Y_max = 0;
    calibration_data->Z_max = 0;
    calibration_data->firstCalibFlag = true;
    sem_post(calib_semaphore);

// -------> Config file <-------
    // Read config file for the first time, if there is no file set the 
    //  configuration with default data.
    if(readAndUpdateCfg() < 0){
        sem_wait(cfg_semaphore);
        configValues_data->backlog = 2;
        configValues_data->current_connections = 0;
        configValues_data->max_connections = 1000;
        configValues_data->mean_samples = 5;
        configValues_data->sensor_period = 1;
        configValues_data->X_HardOffset = -116;
        configValues_data->Y_HardOffset = 222;
        sem_post(cfg_semaphore);
    }

// -------> Socket creation <-------
    sock_http = socket(AF_INET, SOCK_STREAM,0);
    if (sock_http == -1){
        shmdt(sharedMemPtr);
        print_error(__FILE__, "Socket not created");
        
        exit(1);
    }

    // Asigna el puerto indicado y una IP de la maquina
    datosServidor.sin_family = AF_INET;
    datosServidor.sin_port = htons(atoi(argv[1]));
    datosServidor.sin_addr.s_addr = htonl(INADDR_ANY);

    // For reuse TCP port. When a process is closed linux takes time to free the
    // port.
    int reuse = 1;
    if (setsockopt(sock_http, SOL_SOCKET, SO_REUSEADDR, (const char*)&reuse, 
                                                            sizeof(reuse)) < 0){
        print_error(__FILE__, "setsockopt(SO_REUSEADDR) failed");
    }

#ifdef SO_REUSEPORT
    if (setsockopt(sock_http, SOL_SOCKET, SO_REUSEPORT, (const char*)&reuse, 
                                                            sizeof(reuse)) < 0){
        print_error(__FILE__, "setsockopt(SO_REUSEPORT) failed");
    }
#endif

    // Obtiene el puerto para este proceso.
    if( bind(sock_http, (struct sockaddr*)&datosServidor,
                                                sizeof(datosServidor)) == -1){
        shmdt(sharedMemPtr);
        close(sock_http);
        print_error(__FILE__, "Can't bind to requested port");
        
        exit(1);
    }
        
    // Indicates the socket to heap up to "backlog" 
    //  concurrent connections.
    sem_wait(cfg_semaphore);
    backlog_aux = configValues_data->backlog;
    sem_post(cfg_semaphore);
    if (listen(sock_http, backlog_aux) < 0){
        shmdt(sharedMemPtr);
        close(sock_http);
        print_error(__FILE__, "Error in listen");
        
        exit(1);
    }

// -------> Sensor process <-------
    // Start sensor values query process.
    sensor_query_pid = fork();

    if (sensor_query_pid < 0){
        shmdt(sharedMemPtr);
        close(sock_http);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        sem_unlink ("calib_semaphore");
        sem_close(calib_semaphore);
        sem_unlink ("cfg_semaphore");
        sem_close(cfg_semaphore);
        print_error(__FILE__, "Can't open sensor process");
        
        exit(1);
    }
    if (sensor_query_pid == 0){ // Child process.       
        sensor_query();
        
        exit(0);
    }

// -------> User info. <-------
    print_msg(__FILE__, "Go to this path in your browser:");
    print_msg_wValue(__FILE__, "\thttp://server_ip_addr:%s/callib", 
                                                                (long)argv[1]);
    print_msg_wValue(__FILE__, "\tor http://server_ip_addr:%s/compass\n", 
                                                                (long)argv[1]);
    
// -------> Client process <-------
    // Allows serving multiple users.
    while (!exit_flag){
        int s_aux;
        struct sockaddr_in clientData;

        // If there are to many requests, waits until someone ends.
        sem_wait(cfg_semaphore);
        while(max_connected){
            max_connected = (configValues_data->current_connections >= 
                configValues_data->max_connections) ? true : false;
        }
        sem_post(cfg_semaphore);

        // Update configuration values.
        if(updateConfig() < 0){
            close(sock_http);
            sem_unlink ("data_semaphore");
            sem_close(data_semaphore);
            sem_unlink ("calib_semaphore");
            sem_close(calib_semaphore);
            sem_unlink ("cfg_semaphore");
            sem_close(cfg_semaphore);
            print_error(__FILE__, 
                    "Error while trying to read data from configuration file");

            exit(1);
        }

        // If there are no clients, the server should not be blocked by 
        // accept(). With select () a timer waits for new data on the socket, 
        // if there is no data on the socket the server skips from accept ().
        FD_ZERO(&readfds);
        FD_SET(sock_http, &readfds);

        timeout.tv_sec = 1;
        timeout.tv_usec = 0;

        sret = select(8, &readfds, NULL, NULL, &timeout);
        if(sret > 0){
            // accept() fills up the addres structure with the client 
            // information and places the struct length in longDirec  
            longDirec = sizeof(clientData);
            s_aux = accept(sock_http, (struct sockaddr*) &clientData, &longDirec);
            if (s_aux < 0){
                close(sock_http);
                sem_unlink ("data_semaphore");
                sem_close(data_semaphore);
                sem_unlink ("calib_semaphore");
                sem_close(calib_semaphore);
                sem_unlink ("cfg_semaphore");
                sem_close(cfg_semaphore);
                print_error(__FILE__, "\"accept()\" error");

                exit(1);
            }

            httpClient_pid = fork();

            if (httpClient_pid < 0){
                close(sock_http);
                sem_unlink ("data_semaphore");
                sem_close(data_semaphore);
                sem_unlink ("calib_semaphore");
                sem_close(calib_semaphore);
                sem_unlink ("cfg_semaphore");
                sem_close(cfg_semaphore);
                print_error(__FILE__, "Can't create http process");

                exit(1);
            }
            if (httpClient_pid == 0){ // Child process.
                // Increment "current connections" count.
                sem_wait(calib_semaphore);
                configValues_data->current_connections++;
                sem_post(calib_semaphore);

                processClient(s_aux, &clientData, atoi(argv[1]));

                // Decrement "current connections" count.
                sem_wait(calib_semaphore);
                (configValues_data->current_connections > 0) ? 
                               configValues_data->current_connections-- : 
                               0;
                sem_post(calib_semaphore);

                exit(0);
            }
            close(s_aux);  // The parent process must close childs socket.
        }
    }
    shmdt(sharedMemPtr);
    close(sock_http);
    sem_unlink ("data_semaphore");
    sem_close(data_semaphore);
    sem_unlink ("calib_semaphore");
    sem_close(calib_semaphore);
    sem_unlink ("cfg_semaphore");
    sem_close(cfg_semaphore);
}

void SIGINT_handler (int signbr) {
    exit_flag = true;
    printf("\n");
    print_msg(__FILE__, "Exiting server and closing sensor process.");
}

void SIGCHLD_handler (int signbr) {
    pid_t child_pid;
    int status_child;
    while((child_pid = waitpid(-1, &status_child, WNOHANG)) > 0) {
      //   print_msg_wValue(__FILE__, "Dead child PID: %d", (long)child_pid);
    }
    return;
}

void SIGUSR1_handler (int signbr) {
    config_flag = true;
    print_msg(__FILE__, "Updating configuration.");
    return;
}