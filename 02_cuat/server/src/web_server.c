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
/* http://dominio/tempCelsius (número): genera respuesta  */
/* con temperatura en Celsius indicado por el usuario y   */
/* en Fahrenheit.                                         */
/**********************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#define MAX_CONN 10 //Nro maximo de conexiones en espera

void ProcesarCliente(int s_aux, struct sockaddr_in *pDireccionCliente,
                     int puerto);

/**********************************************************/
/* funcion MAIN                                           */
/* Orden Parametros: Puerto                               */
/**********************************************************/
int main(int argc, char *argv[])
{
  int s;
  struct sockaddr_in datosServidor;
  socklen_t longDirec;

  if (argc != 2)
  {
    printf("\n\nLinea de comandos: webserver Puerto\n\n");
    exit(1);
  }
  // Creamos el socket
  s = socket(AF_INET, SOCK_STREAM,0);
  if (s == -1)
  {
    printf("ERROR: El socket no se ha creado correctamente!\n");
    exit(1);
  }
  // Asigna el puerto indicado y una IP de la maquina
  datosServidor.sin_family = AF_INET;
  datosServidor.sin_port = htons(atoi(argv[1]));
  datosServidor.sin_addr.s_addr = htonl(INADDR_ANY);

  // Obtiene el puerto para este proceso.
  if( bind(s, (struct sockaddr*)&datosServidor,
           sizeof(datosServidor)) == -1)
  {
    printf("ERROR: este proceso no puede tomar el puerto %s\n",
           argv[1]);
    exit(1);
  }
  printf("\nIngrese en el navegador http://dir ip servidor:%s/gradosCelsius\n",
         argv[1]);
  // Indicar que el socket encole hasta MAX_CONN pedidos
  // de conexion simultaneas.
  if (listen(s, MAX_CONN) < 0)
  {
    perror("Error en listen");
    close(s);
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
    s_aux = accept(s, (struct sockaddr*) &datosCliente, &longDirec);
    if (s_aux < 0)
    {
      perror("Error en accept");
      close(s);
      exit(1);
    }
    pid = fork();
    if (pid < 0)
    {
      perror("No se puede crear un nuevo proceso mediante fork");
      close(s);
      exit(1);
    }
    if (pid == 0)
    {       // Proceso hijo.
      ProcesarCliente(s_aux, &datosCliente, atoi(argv[1]));
      exit(0);
    }
    close(s_aux);  // El proceso padre debe cerrar el socket
                   // que usa el hijo.
  }
}

void ProcesarCliente(int s_aux, struct sockaddr_in *pDireccionCliente,
                     int puerto)
{
  char bufferComunic[4096];
  char ipAddr[20];
  int Port;
  int indiceEntrada;
  float tempCelsius;
  int tempValida = 0;
  char HTML[4096];
  char encabezadoHTML[4096];
  
  strcpy(ipAddr, inet_ntoa(pDireccionCliente->sin_addr));
  Port = ntohs(pDireccionCliente->sin_port);
  // Recibe el mensaje del cliente
  if (recv(s_aux, bufferComunic, sizeof(bufferComunic), 0) == -1)
  {
    perror("Error en recv");
    exit(1);
  }
  printf("* Recibido del navegador Web %s:%d:\n%s\n",
         ipAddr, Port, bufferComunic);
  
  // Obtener la temperatura desde la ruta.
  if (memcmp(bufferComunic, "GET /", 5) == 0)
  {
    if (sscanf(&bufferComunic[5], "%f", &tempCelsius) == 1)
    {      // Conversion done successfully.
      tempValida = 1;
    }
  }
  
  // Generar HTML.
  // El viewport es obligatorio para que se vea bien en
  // dispositivos móviles.
  sprintf(encabezadoHTML, "<html><head><title>Temperatura</title>"
            "<meta name=\"viewport\" "
            "content=\"width=device-width, initial-scale=1.0\">"
            "</head>"
            "<h1>Temperatura</h1>");
  if (tempValida)
  {
    sprintf(HTML, 
            "%s<p>%f grados Celsius equivale a %f grados Fahrenheit</p>",
            encabezadoHTML, tempCelsius, tempCelsius * 1.8 + 32);
  }
  else
  {
    sprintf(HTML, 
            "%s<p>El URL debe ser http://dominio:%d/gradosCelsius.</p>",
            encabezadoHTML, puerto);
  }

  sprintf(bufferComunic,
          "HTTP/1.1 200 OK\n"
          "Content-Length: %d\n"
          "Content-Type: text/html; charset=utf-8\n"
          "Connection: Closed\n\n%s",
          strlen(HTML), HTML);

  printf("* Enviado al navegador Web %s:%d:\n%s\n",
         ipAddr, Port, bufferComunic);
  
  // Envia el mensaje al cliente
  if (send(s_aux, bufferComunic, strlen(bufferComunic), 0) == -1)
  {
    perror("Error en send");
    exit(1);
  }
  // Cierra la conexion con el cliente actual
  close(s_aux);
}

