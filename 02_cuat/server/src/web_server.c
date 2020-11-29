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

int sensor_query ();
void compassAnswer (char* commBuffer);
void calibAnswer(char* commBuffer, struct calibValues calVal);
void setCalToZero();
void processClient(int s_aux, struct sockaddr_in *pDireccionCliente,
                     int puerto);
void SIGINT_handler (int signbr);

/**********************************************************/
/* funcion MAIN                                           */
/* Orden Parametros: Puerto                               */
/**********************************************************/
int main(int argc, char *argv[])
{
    int sock;
    struct sockaddr_in datosServidor;
    socklen_t longDirec;

    signal(SIGINT, SIGINT_handler);

    if (argc != 2)
    {
        printf("\n\nLinea de comandos: webserver Puerto\n\n");
        exit(1);
    }
    // Creamos el socket
    sock = socket(AF_INET, SOCK_STREAM,0);
    if (sock == -1)
    {
        printf("ERROR: El socket no se ha creado correctamente!\n");
        exit(1);
    }
    // Asigna el puerto indicado y una IP de la maquina
    datosServidor.sin_family = AF_INET;
    datosServidor.sin_port = htons(atoi(argv[1]));
    datosServidor.sin_addr.s_addr = htonl(INADDR_ANY);

    // Obtiene el puerto para este proceso.
    if( bind(sock, (struct sockaddr*)&datosServidor,
                                                sizeof(datosServidor)) == -1)
    {
        printf("ERROR: este proceso no puede tomar el puerto %s\n", argv[1]);
        exit(1);
    }
    printf("\nIngrese en el navegador");
    printf(" http://dir ip servidor:%s/gradosCelsius\n", argv[1]);
    // Indicar que el socket encole hasta MAX_CONN pedidos
    // de conexion simultaneas.
    if (listen(sock, MAX_CONN) < 0)
    {
        perror("Error en listen");
        close(sock);
        exit(1);
    }
    // Permite atender a multiples usuarios
    while (1)
    {
        int pid, s_aux;
        struct sockaddr_in datosCliente;
        // La funcion accept rellena la estructura address con
        // informacion del cliente y pone en longDirec la longitud
        // de la estructura.
        longDirec = sizeof(datosCliente);
        s_aux = accept(sock, (struct sockaddr*) &datosCliente, &longDirec);
        if (s_aux < 0)
        {
            perror("Error en accept");
            close(sock);
            exit(1);
        }
        pid = fork();
        if (pid < 0)
        {
            perror("No se puede crear un nuevo proceso mediante fork");
            close(sock);
            exit(1);
        }
        if (pid == 0)
        {       // Proceso hijo.
            processClient(s_aux, &datosCliente, atoi(argv[1]));
            exit(0);
        }
        close(s_aux);  // El proceso padre debe cerrar el socket
                   // que usa el hijo.
    }
}

void processClient(int s_aux, struct sockaddr_in *pDireccionCliente,
                     int puerto)
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
  
    sensor_query();

    printf("GET: %s\n", sensorOption);

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
    if (fd > 0) {
        close(fd);
    }
    printf("\nLSM303 closed\n\n");
    exit(0);
}
