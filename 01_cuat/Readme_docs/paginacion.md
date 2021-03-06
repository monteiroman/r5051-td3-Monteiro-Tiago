## Paginación

Existe una tabla de paginación propuesta por la cátedra que fue la que se siguió en este proyecto. Se utilizaron 4 directorios para el programa, cada uno correspondía a una tarea (3 en total) y un cuarto que correspondía a kernel. Este último es el que se explica con mayor detalle en la sección _Estructura de tablas para Kernel_. Los otros tres son similares pero sin las secciones correspondientes a las otras tareas.

Cabe aclarar que una vez que el scheduler empieza a distribuir el uso del procesador entre las tareas, el directorio de kernel no se vuelve a utilizar.

#### Mapa de paginación

El mapa de paginación propuesto para este proyecto se muestra a continuación. Se agregaron también los índices que se obtienen a partir de las direcciones lineales de cada sección.

|Sección|Dirección física inicial|Dirección lineal inicial|Indice en Directorio de Paginas (1° Tabla de Pagina)|Indice en Tabla de Paginas (1° Pagina)| 
|:---:|:---:|:---:|:---:|:---:|
|ISR                 |00000000h|00000000h|0x000|0x000|
|Video               |000B8000h|00010000h|0x000|0x010|
|Tablas de sistema   |00100000h|00100000h|0x000|0x100|
|Tablas de paginación|00110000h|00110000h|0x000|0x110|
|Núcleo              |00200000h|01200000h|0x004|0x200|
|Datos               |00202000h|01202000h|0x004|0x202|
|Tabla de dígitos    |00210000h|01210000h|0x004|0x210|
|TEXT Tarea 1        |00300000h|01300000h|0x004|0x300|
|BSS Tarea 1         |00301000h|01301000h|0x004|0x301|
|DATA Tarea 1        |00302000h|01302000h|0x004|0x302|
|TEXT Tarea 2        |00310000h|01310000h|0x004|0x310|
|BSS Tarea 2         |00311000h|01311000h|0x004|0x311|
|DATA Tarea 2        |00312000h|01312000h|0x004|0x312|
|TEXT Tarea 3        |00320000h|01320000h|0x004|0x320|
|BSS Tarea 3         |00321000h|01321000h|0x004|0x321|
|DATA Tarea 3        |00322000h|01322000h|0x004|0x322|
|Pila Nucleo         |1FF08000h|1FF08000h|0x07F|0x308|
|Pila Tarea 3        |1FFFD000h|00713000h|0x001|0x313|
|Pila Tarea 2        |1FFFE000h|00713000h|0x001|0x313|
|Pila Tarea 1        |1FFFF000h|00713000h|0x001|0x313|
|Secuencia inic. ROM |FFFF0000h|FFFF0000h|0x3FF|0x3F0|
|Vector de reset     |FFFFFFF0h|FFFFFFF0h|0x3FF|0x3FF|


#### Estructura de tablas para Kernel

Como se mencionó anteriormente, solo se explica la estructura de tablas para kernel ya que para las tareas es igual salvo porque no se incluyen en el directorio las secciones de memoria que no correspondan a la tarea en ejecución.


Base del Directorio: 0x00110000 (mem.fis.)

Base de la Tabla de Paginas: 0x00114000 (mem.fis.)

|Entrada en Directorio|Ubicacion en Directorio (direccion física)|Va a guardar la direccion|Entrada de Tabla|Ubicacion en la Tabla (direccion física)|Va a guardar la direccion|
|:---:|:---:|:---:|:---:|:---:|:---:|
|Tabla 1|IdxDir = 0x3FF (0x00110FFC)|0x00114000 + Atributos|Inicializacion ROM  |IdxTab = 0x3F0 (0x00114FC0)|0xFFFF0000 + Atributos|
|Tabla 1|IdxDir = 0x3FF (0x00110FFC)|0x00114000 + Atributos|Reset               |IdxTab = 0x3FF (0x00114FFC)|0xFFFFF000 + Atributos|
|Tabla 2|IdxDir = 0x000 (0x00110000)|0x00115000 + Atributos|ISR                 |IdxTab = 0x000 (0x00115000)|0x00000000 + Atributos|
|Tabla 2|IdxDir = 0x000 (0x00110000)|0x00115000 + Atributos|Video               |IdxTab = 0x010 (0x00115040)|0x000B8000 + Atributos|
|Tabla 2|IdxDir = 0x000 (0x00110000)|0x00115000 + Atributos|Tablas del Sistema  |IdxTab = 0x100 (0x00115400)|0x00100000 + Atributos|
|Tabla 2|IdxDir = 0x000 (0x00110000)|0x00115000 + Atributos|Tablas de Paginacion|IdxTab = 0x110 (0x00115440)|0x00110000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|Nucleo              |IdxTab = 0x200 (0x00116800)|0x00200000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|Tablas de Digitos   |IdxTab = 0x210 (0x00116840)|0x00210000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|Datos               |IdxTab = 0x202 (0x00116808)|0x00202000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|TEXT Tarea 1        |IdxTab = 0x300 (0x00116C00)|0x00300000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|BSS Tarea 1         |IdxTab = 0x301 (0x00116C04)|0x00301000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|DATA R Tarea 1      |IdxTab = 0x302 (0x00116C08)|0x00302000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|DATA RW Tarea 1     |IdxTab = 0x303 (0x00116C0C)|0x00303000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|TEXT Tarea 2        |IdxTab = 0x310 (0x00116C40)|0x00310000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|BSS Tarea 2         |IdxTab = 0x311 (0x00116C44)|0x00311000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|DATA R Tarea 2      |IdxTab = 0x312 (0x00116C48)|0x00312000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|DATA RW Tarea 2     |IdxTab = 0x313 (0x00116C4C)|0x00313000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|TEXT Tarea 3        |IdxTab = 0x320 (0x00116C80)|0x00320000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|BSS Tarea 3         |IdxTab = 0x321 (0x00116C84)|0x00321000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|DATA R Tarea 3      |IdxTab = 0x322 (0x00116C88)|0x00322000 + Atributos|
|Tabla 3|IdxDir = 0x004 (0x00110010)|0x00116000 + Atributos|DATA RW Tarea 3     |IdxTab = 0x323 (0x00116C8C)|0x00323000 + Atributos|
|Tabla 4|IdxDir = 0x07F (0x001101FC)|0x00117000 + Atributos|Pila Nucleo         |IdxTab = 0x308 (0x00117C20)|0x1FF08000 + Atributos|


A partir de la dirección física 0x08000000 se guardan las paginas no mapeadas al inicio del programa (esta funcionalidad era requerida para el ejercicio 12 luego de éste se pedía que no se borre pero que se deshabilite).

Para las paginas de las tareas se aplica la misma lógica. En cada una de las tareas se paginó todo lo que sea de privilegio 0 mas lo que corresponde a cada una con sus respectivas pilas.

   El directorio de la Tarea 1 comienza en 111000 y las tablas en 0x0017E000.
   
   El directorio de la Tarea 2 comienza en 112000 y las tablas en 0x00183000.
   
   El directorio de la Tarea 3 comienza en 113000 y las tablas en 0x00188000.
   
Se debe tener en cuenta que el atributo que se guarda en la tabla es el que primero se ingresa, es decir, con el que se genera por primera vez la tabla.
  
  Por ejemplo: 
  
  El atributo de la tabla 3 será el que se pase a la función paging al paginar las direcciones de memoria de la sección llamada KERNEL que es la primera que se pagina.