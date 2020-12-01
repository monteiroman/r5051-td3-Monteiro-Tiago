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
/* con temperatura en Celsius indicado por el usuario y   */
/* en Fahrenheit.                                         */
/**********************************************************/
#include "../inc/web_server.h"

int fd = 0;
int sock_http;
void *sharedMemPtr = (void *) 0;
sem_t *data_semaphore;
struct sensorValues *sensorValues_data, LSM303_values;


/**********************************************************/
/* funcion MAIN                                           */
/* Orden Parametros: Puerto                               */
/**********************************************************/
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
    // Point shared memory to the corresponding struct.
    sensorValues_data = (struct sensorValues *)sharedMemPtr;
    
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
        print_error(__FILE__, "Can't create semaphore");

        return -1;
    }

// -------> Sensor process <-------
    // Start sensor values query process.
    sensor_query_pid = fork();

    if (sensor_query_pid < 0)
    {
        shmdt(sharedMemPtr);
        close(sock_http);
        sem_unlink ("data_semaphore");
        sem_close(data_semaphore);
        print_error(__FILE__, "Can not open sensor process");
        
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
    printf("\n\to http://server_ip_addr:%s/compass\n", argv[1]);

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
            perror("Error en accept");
            close(sock_http);
            exit(1);
        }
        httpClient_pid = fork();
        if (httpClient_pid < 0)
        {
            perror("No se puede crear un nuevo proceso mediante fork");
            close(sock_http);
            exit(1);
        }
        if (httpClient_pid == 0)
        {       // Proceso hijo.
            processClient(s_aux, &clientData, atoi(argv[1]));
            exit(0);
        }
        close(s_aux);  // El proceso padre debe cerrar el socket
                   // que usa el hijo.
    }
}

void processClient(int s_aux, struct sockaddr_in *pDireccionCliente, int puerto)
{
    char commBuffer[4096];
    char ipAddr[20];
    int Port;
    int indiceEntrada;
    char sensorOption[6];
    int tempValida = 0;
  
    strcpy(ipAddr, inet_ntoa(pDireccionCliente->sin_addr));
    Port = ntohs(pDireccionCliente->sin_port);
    // Recibe el mensaje del cliente
    if (recv(s_aux, commBuffer, sizeof(commBuffer), 0) == -1)
    {
        perror("Error en recv");
        exit(1);
    }
    // printf("\n>=======================<\n* Recibido");
    // printf(" del navegador Web %s:%d:\n%s\n", ipAddr, Port, commBuffer);
  
    // Obtener la temperatura desde la ruta.
    if (memcmp(commBuffer, "GET /", 5) == 0)
    {
        if (sscanf(&commBuffer[5], "%s", &sensorOption) == 1)
        {      // Conversion done successfully.
            tempValida = 1;
        }
    }
  
    // printf("GET: %s\n", sensorOption);

    if(memcmp(sensorOption, "compass", 7) == 0)
        compassAnswer(commBuffer);

    if(memcmp(sensorOption, "calib", 5) == 0){
        setCalToZero();
        calibAnswer(commBuffer, calVal);
    }

    // printf("\n>=======================<\n* Enviado al navegador Web %s:%d:\n%s\n",
                            // ipAddr, Port, commBuffer);
    
    // Envia el mensaje al cliente
    if (send(s_aux, commBuffer, strlen(commBuffer), 0) == -1)
    {
        perror("Error en send");
        exit(1);
    }
    
    // Cierra la conexion con el cliente actual
    close(s_aux);
}

void compassAnswer(char* commBuffer)
{
    float heading = 0;
    float LSM303_compass_x = 0;
    float LSM303_compass_y = 0;
    float LSM303_compass_z = 0;
    char encabezadoHTML[4096];
    char HTML[4096];
    bool not_valid_heading;

    // Wait semaphore and get sensor data. 
    sem_wait(data_semaphore);
    LSM303_values.X_acc = sensorValues_data->X_acc;
    LSM303_values.Y_acc = sensorValues_data->Y_acc;
    LSM303_values.Z_acc = sensorValues_data->Z_acc;
    LSM303_values.X_mag = sensorValues_data->X_mag;
    LSM303_values.Y_mag = sensorValues_data->Y_mag;
    LSM303_values.Z_mag = sensorValues_data->Z_mag;
    sem_post(data_semaphore);

    // Calculate the angle of the vector y,x
    float X_uTesla = (float)(LSM303_values.X_mag + X_MAG_HARDOFFSET);
    float Y_uTesla = (float)(LSM303_values.Y_mag + Y_MAG_HARDOFFSET);

    heading = ((float)(atan2(Y_uTesla, X_uTesla) * 180) / M_PI);

    // Normalize to 0-360
    if (heading < 0){
        heading = 360 + heading;
    }

    LSM303_compass_x = (float)LSM303_values.X_acc * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    LSM303_compass_y = (float)LSM303_values.Y_acc * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    LSM303_compass_z = (float)LSM303_values.Z_acc * LSM303ACC_G_LSB * 
                                                            LSM303ACC_GRAVITY;
    
    not_valid_heading = (LSM303_compass_z < STRAIGHT_SENSOR_G) ? true : false;

    // Generar HTML.
    // El viewport es obligatorio para que se vea bien en
    // dispositivos móviles.
    sprintf(encabezadoHTML, "<html><head><title>Temperatura</title>"
            "<meta name=\"viewport\" "
            "content=\"width=device-width, initial-scale=1.0\">"
            "<meta http-equiv=\"refresh\" content=\"1\">"
            "</head>"
            "<h1>Temperatura</h1>");
    
    sprintf(HTML, "%s<p> El sensor esta apuntando a: %.2f°</p>"
            "<p>Aceleracion:</p><p> X: %.2fm/s^2 "
            "Y: %.2fm/s^2 Z: %.2fm/s^2</p>", encabezadoHTML, 
            heading, LSM303_compass_x, LSM303_compass_y,
            LSM303_compass_z);

    if(not_valid_heading)
    {
        sprintf(HTML, 
            "%s<p>La informacion no es valida. Enderese el sensor</p>",HTML);
    }
            
    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Length: %d\n"
            "Content-Type: text/html; charset=utf-8\n"
            "Connection: Closed\n\n%s",
            strlen(HTML), HTML);
}

void calibAnswer(char* commBuffer, struct calibValues calVal)
{
    char encabezadoHTML[4096];
    char HTML[4096];

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

    // Generar HTML.
    // El viewport es obligatorio para que se vea bien en
    // dispositivos móviles.
    sprintf(encabezadoHTML, "<html><head><title>Temperatura</title>"
            "<meta name=\"viewport\" "
            "content=\"width=device-width, initial-scale=1.0\">"
            "<meta http-equiv=\"refresh\" content=\"1\">"
            "</head>"
            "<h1>Temperatura</h1>");
    
    sprintf(HTML, "%s<p> Calibracion:</p>"
            "<p> Xmed: %.2f"
            "Ymed: %.2f Z: %.2f</p>", encabezadoHTML, 
            midX, midY, midZ);
            
    sprintf(commBuffer,
            "HTTP/1.1 200 OK\n"
            "Content-Length: %d\n"
            "Content-Type: text/html; charset=utf-8\n"
            "Connection: Closed\n\n%s",
            strlen(HTML), HTML);
}

void setCalToZero(){
    calVal.X_min = 0; 
    calVal.Y_min = 0; 
    calVal.Z_min = 0; 
    calVal.X_max = 0; 
    calVal.Y_max = 0; 
    calVal.Z_max = 0;
}

void SIGINT_handler (int signbr) {
    shmdt(sharedMemPtr);
    close(sock_http);
    sem_unlink ("data_semaphore");
    sem_close(data_semaphore);
    
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