/**********************************************************/
/* Mini web server por Dario Alpern (17/8/2020)           */
/*                                                        */
/* Headers HTTP relevantes del cliente:                   */
/* GET {path} HTTP/1.x                                    */
/*                                                        */
/* Encabezados HTTP del servidor enviados como respuesta: */
/* HTTP/1.1 200 OK                                        */
/* Content-Length: nn (longitud del HTML)                 */
/* Content-Type: text/html; charset=utf-8                 */
/* Connection: Closed                                     */
/*                                                        */
/* Después de los encabezados va una lìnea en blanco y    */
/* luego el código HTML.                                  */
/*                                                        */
/* http://dominio/sensorOption (número): genera respuesta  */
/* con Brujula en Celsius indicado por el usuario y   */
/* en Fahrenheit.                                         */
/**********************************************************/
#include "../inc/web_server.h"

int sock_http;
void *sharedMemPtr = (void *) 0;
sem_t *data_semaphore, *calib_semaphore;
struct sensorValues *sensorValues_data, LSM303_values;
struct calibValues *calibration_data, calVal;


int main(int argc, char *argv[])
{
    struct sockaddr_in datosServidor;
    socklen_t longDirec;
    pid_t server_pid, httpClient_pid, sensor_query_pid;
    int sharedMemId;

// -------> Help <-------
    if (argc != 2)
    {
        printf("\n\nLinea de comandos: webserver Puerto\n\n");
        
        exit(1);
    }

    server_pid = getpid();
    printf("[LOG] Web Server: Server pid: %d\n", server_pid);

// -------> Signal handlers <-------
    signal(SIGINT, SIGINT_handler);
    signal(SIGCHLD, SIGCHLD_handler);

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
    printf("[LOG] TCP SOCKET: Shared memory attached at %p\n", sharedMemPtr);
    
    // Point the struct to the corresponding shared memory.
    sensorValues_data = (struct sensorValues *)sharedMemPtr;
    calibration_data = (struct calibValues *)
                    (sharedMemPtr + sizeof(struct sensorValues) + DATA_MARGIN);
 
// -------> Socket creation <-------
    sock_http = socket(AF_INET, SOCK_STREAM,0);
    if (sock_http == -1)
    {
        shmdt(sharedMemPtr);
        print_error(__FILE__, "Socket not created");
        
        exit(1);
    }
    // Asigna el puerto indicado y una IP de la maquina
    datosServidor.sin_family = AF_INET;
    datosServidor.sin_port = htons(atoi(argv[1]));
    datosServidor.sin_addr.s_addr = htonl(INADDR_ANY);

    // Obtiene el puerto para este proceso.
    if( bind(sock_http, (struct sockaddr*)&datosServidor,
                                                sizeof(datosServidor)) == -1)
    {
        shmdt(sharedMemPtr);
        close(sock_http);
        print_error(__FILE__, "Can't bind to the requested port");
        
        exit(1);
    }
        
    // Indicar que el socket encole hasta MAX_CONN pedidos
    // de conexion simultaneas.
    if (listen(sock_http, MAX_CONN) < 0)
    {
        shmdt(sharedMemPtr);
        close(sock_http);
        print_error(__FILE__, "Error in listen");
        
        exit(1);
    }

// -------> Semaphores <-------
    sem_unlink ("data_semaphore");
    data_semaphore = sem_open ("data_semaphore", O_CREAT | O_EXCL, 0644, 1);
    if (data_semaphore < 0)
    {
        shmdt(sharedMemPtr);
        close(sock_http);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        print_error(__FILE__, "Can't create data semaphore");

        return -1;
    }

    sem_unlink ("calib_semaphore");
    calib_semaphore = sem_open ("calib_semaphore", O_CREAT | O_EXCL, 0644, 1);
    if (calib_semaphore < 0)
    {
        shmdt(sharedMemPtr);
        close(sock_http);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        sem_unlink ("calib_semaphore");
        sem_close(calib_semaphore);
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

// -------> Sensor process <-------
    // Start sensor values query process.
    sensor_query_pid = fork();

    if (sensor_query_pid < 0)
    {
        shmdt(sharedMemPtr);
        close(sock_http);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        sem_unlink ("calib_semaphore");
        sem_close(calib_semaphore);
        print_error(__FILE__, "Can't open sensor process");
        
        exit(1);
    }
    if (sensor_query_pid == 0) // Child process.
    {       
        sensor_query();
        
        exit(0);
    }

// -------> User info. <-------
    printf("\nGo to this path in your browser:");
    printf("\n\thttp://server_ip_addr:%s/callib", argv[1]);
    printf("\n\tor http://server_ip_addr:%s/compass\n", argv[1]);

// -------> Client process <-------
    // Permite atender a multiples usuarios
    while (1)
    {
        int s_aux;
        struct sockaddr_in clientData;
        // La funcion accept rellena la estructura address con
        // informacion del cliente y pone en longDirec la longitud
        // de la estructura.
        longDirec = sizeof(clientData);
        s_aux = accept(sock_http, (struct sockaddr*) &clientData, &longDirec);
        if (s_aux < 0)
        {
            close(sock_http);
            sem_unlink ("data_semaphore");
            sem_close(data_semaphore);
            sem_unlink ("calib_semaphore");
            sem_close(calib_semaphore);
            print_error(__FILE__, "\"accept()\" error");

            exit(1);
        }
        httpClient_pid = fork();
        if (httpClient_pid < 0)
        {
            close(sock_http);
            sem_unlink ("data_semaphore");
            sem_close(data_semaphore);
            sem_unlink ("calib_semaphore");
            sem_close(calib_semaphore);
            print_error(__FILE__, "Can't create process with \"fork()\"");
            
            exit(1);
        }
        if (httpClient_pid == 0) // Child process.
        {
            processClient(s_aux, &clientData, atoi(argv[1]));
            
            exit(0);
        }
        close(s_aux);  // El proceso padre debe cerrar el socket
                   // que usa el hijo.
    }
}

void SIGINT_handler (int signbr) {
    shmdt(sharedMemPtr);
    close(sock_http);
    sem_unlink ("data_semaphore");
    sem_close(data_semaphore);
    sem_unlink ("calib_semaphore");
    sem_close(calib_semaphore);
    
    printf("\nParent\n\n");
    exit(0);
}

void SIGCHLD_handler (int signbr) {
  pid_t child_pid;
  int status_child;
  while((child_pid = waitpid(-1, &status_child, WNOHANG)) > 0) {
    // printf("[LOG] TCP SOCKET: Dead child PID: %d\n", child_pid);
  }
  return;
}