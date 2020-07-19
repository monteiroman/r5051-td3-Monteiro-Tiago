## Teclado

Cada vez que se presiona una tecla, esta se guarda en el buffer circular de 9 bytes. Cuando se presiona la tecla enter se copian los caracteres ingresados que estaban guardados en el buffer a memoria.

Cada vez que se presiona una tecla esta se interpreta como un símbolo de 4 bits, es decir que en un byte entran 2. Por esta razón se eligió llenar el buffer en el orden que van llegando los caracteres y luego se los ordena para guardarlos en memoria.

Soy conciente que no debe ser lo óptimo pero a esa altura del año fué lo que mejor me salió.

#### Buffer de teclado

El buffer de teclado, como se mencionó anteriormente, se llena en el orden en que van llegando los simbolos. Es decir que si uno presiona la secuencia "1000" primero se guardará el número 1 y luego los 3 ceros quedando el 1 en la posición menos significativa y los ceros en las pocisiones de mayor peso. En este sentido me encontré en un problema ya que el número tiene que estar exactamente al revés de como se encuentra en el buffer. Esto en sí no es problema de la función "save_number_in_buffer" ya que solo se limita a guardar el numero que se ingresó hasta que se presiona la tecla Enter. 

Luego de presionar la tecla Enter el programa salta directamente a la función "save_buffer" que es la que se encarga de acomodar mis digitos.

#### Guardado de caractes en la lista

En el proyecto se dispone de una lista de 64kb para guardar los números ingresados, cada uno de 64 bits, es decir, 8 bytes. Esta lista es circular, por ende una vez que se llena hay que comenzar nuevamente desde el principio a guardar los números.

En esta lista los números tienen que ser guardados en el orden correcto para que los registros puedan levantar el numero directamente desde ella. Por esta razón (y por lo explicado en la sección anterior) se realizó el guardado de los dígitos teniendo en cuenta dos posibilidades.

###### Que la cantidad de nibles en el buffer sea par

En este caso puedo levantar byte a byte desde el buffer circular. RECORRO EN DIRECCION INVERSA AL LLENADO.

Ejemplo: En este caso se ingresaron 20 números y se tienen que guardar los ultimos 16 en memoria, es por esto que los números del byte 1 no son de importancia. 

Buffer circular:

![Alt text](01_cuat/Readme_docs/img/buf_circ_par.png)

Número guardado en memoria: (Para poder levantarlo en un registro)

![Alt text](01_cuat/Readme_docs/img/en_mem.png)

Siendo:

X: un nible que no tengo que cargar en la tabla.

nX: nible a guardar cuyo número denota su orden de entrada al buffer circular.

###### Que la cantidad de nibles en el buffer sea impar

Cuando la cantidad de nibles es impar el problema que se presenta es que quedan dos nibles cruzados. Estos los tengo que tratar especialmente.

Ejemplo: En este caso se ingresaron 21 números y se tienen que guardar los ultimos 16 en memoria, es por esto que los números del byte 1 no son de importancia. 

Buffer circular:

![Alt text](01_cuat/Readme_docs/img/buf_circ_impar.png)

Número guardado en memoria: (Para poder levantarlo en un registro)

![Alt text](01_cuat/Readme_docs/img/en_mem.png)

Siendo:

X: un nible que no tengo que cargar en la tabla.

nX: nible a guardar cuyo número denota su orden de entrada al buffer circular.



