### Paginación

##### Mapa de paginación

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
