## Teclado

Cada vez que se presiona una tecla, esta se guarda en el buffer circular de 9 bytes. Cuando se presiona la tecla enter se copian los caracteres ingresados que estaban guardados en el buffer a memoria.

Cada vez que se presiona una tecla esta se interpreta como un símbolo de 4 bits, es decir que en un byte entran 2. Por esta razón se eligió llenar el buffer en el orden que van llegando los caracteres y luego se los ordena para guardarlos en memoria.

Soy conciente que no debe ser lo óptimo pero a esa altura del año fué lo que mejor me salió.

#### Buffer de teclado

El buffer de teclado, como se mencionó anteriormente, se llena en el orden en que van llegando los simbolos. Es decir que si uno presiona la secuencia "1000" primero se guardará el número 1 y luego los 3 ceros quedando el 1 en la posición menos significativa y los ceros en las pocisiones de mayor peso. En este sentido me encontré en un problema ya que el número tiene que estar exactamente al revés de como se encuentra en el buffer. Esto en sí no es problema de la función "save_number_in_buffer" ya que solo se limita a guardar el numero que se ingresó hasta que se presiona la tecla Enter. 

Luego de presionar la tecla Enter el programa salta directamente a la función "save_buffer" que es la que se encarga de acomodar mis digitos.

#### Guardado de caractes en la lista

En el proyecto se dispone de una lista de 64kb para guardar los números ingresados. Esta lista es circular, es decir, que una vez que se llena hay que comenzar nuevamente desde el principio a guardar los caracteres.

En esta lista los números tienen que ser guardados en el orden correcto para que los registros puedan levantar el numero directamente desde ella. Por esta razón (y por lo explicado en la sección anterior) se realizó el guardado de los dígitos teniendo en cuenta dos posibilidades.

###### Que la cantidad de nibles sea par

En este casp puedo levanta byte a byte desde el buffer circular. RECORRO EN DIRECCION INVERSA AL LLENADO.

Ejemplo:
Buffer circular:
 __________________________________________________________________________________________________________
|          ||          ||         ||          ||           ||         ||         ||           ||           |
| n14  n15 ||  X    X  || n0   n1 || n2   n3  ||  n4   n5  || n6   n7 || n8   n9 || n10   n11 || n12   n13 |
|____·_____||____·_____||____·____||_____·____||_____·_____||____·____||____·____||_____·_____||_____·_____|
   Byte 0     Byte 1     Byte 2      Byte 3      Byte 4       Byte 5      Byte 6      Byte 7       Byte 8


Posicion de memoria: (Para poder levantarlo en un registro)
 ______________________________________________________________________________________________
|          ||          ||           ||          ||           ||         ||         ||          |
| n14  n15 || n12  n13 || n10   n11 || n8   n9  ||  n6   n7  || n4   n5 || n2   n3 || n0    n1 |
|____·_____||____·_____||_____·_____||_____·____||_____·_____||____·____||____·____||_____·____|
   Byte 0     Byte 1       Byte 2       Byte 3      Byte 4       Byte 5     Byte 6     Byte 7



