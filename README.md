#	Tecnicas Digitales III 2020
	
##	Tiago Monteiro - Legajo: 142035-5

### Archivos del proyecto (Ejercicio_15)

* ###### bios.asm: 
    Es el que se ejecuta luego de as inicializaciones encontradas en init.asm. Se encarga de copiar el kernel a memoria y las rutinas de interrupciones a RAM en primera instancia. Esto se decidió de esta manera para que luego de paginar se pudieran poner esas paginas como solo lectura en todo momento. Luego, se encarga de paginar, llama a la función de paginación y setea los bits correspondientes de CR0 así como también carga el registro CR3. A continuación, se encarga de llenar la tabla que se usa para determinar las teclas presionadas, copiar el resto del código (de las tareas) a RAM, carga la GDT a RAM, inicializa la IDT, el pic y setea los bits necesarios para el uso de SIMD. Por último, llama a la función "scheduler_init" que se encuenta en scheduler.asm para inicializar el Scheduler.

* ###### copy.asm: 
    Este archivo contiene el código para copiar pedazos de memoria. Se utilizó para copiar de ROM a RAM.

* ###### exc_handlers.asm: 
    Contiene todos los handlers de excepciones que se programaron para el proyecto. Cada uno de ellos termina imprimiendo una advertencia en pantalla (si es que fuera posible) y termina en un breakpoint. En el caso de la excepción #NM (Device not available, [0x07]), no se imprime en pantalla ni se termina en un breakpoint ya que es la excepción destinada a restaurar los registros de SIMD.

* ###### init.asm: 
    Archivo que contiene el vector de reset, las inicializaciones de GDT (de ROM y luego reserva espacio para RAM), pasaje a modo protegido y reserva espacio para la IDT en RAM. Como última instancia tiene a la funcion "init_GDT_RAM" que se encarga de pasar a RAM la GDT agregando el selector de la TSS a la misma y se encarga de las inicializaciones de la IDT (carga de excepciones e interrupciones) mediante "init_IDT".

* ###### init_pci.inc: 
    Archivo no escrito por el alumno que fue provisto por la cátedra y que es incluido en "init.asm". Se encarga de inicializar el video en Bochs.

* ###### irq_handlers.asm: 
    Contiene los manejadores de interrupciones, se encarga de manejar las interrupciones de timer, teclaro y system calls (halt, read y print).

* ###### keyboard.asm: 
    Este archivo es el que contiene el código de la atención de la interrupción de teclado "keyboard_routine", la función de escritura en el buffer "save_number_in_buffer" y la función de guardado en memoria del contenido del buffer "save_buffer".
    La función "save_number_in_buffer" usa la tabla que se define al principio del archivo (y que carga bios.asm) para encontrar cual fué la tecla presionada.

* ###### paging.asm: 
    Contiene las funciones encargadas de armar los árboles de paginación de cada tarea. Se pagina un directorio de Kernel y uno para cada tarea. El de Kernel es el usado durante toda la inicialización del programa que luego se deja de usar al comenzar a correr el Scheduler. En cada directorio de tarea se paginaron todas las tablas correspondientes al Kernel mas las correspondientes particularmente a la tarea en ejecición. Es decir, las tareas no pueden verse las páginas entre ellas.

* ###### pic_init.asm: 
    Contiene todo el código dedicado a la inicialixación de los pics encargados del teclado y del timer del sistema.

* ###### scheduler.asm: 
    En él se encuentran todas las funciones encargadas del manejo de tareas en el tiempo.
    Las funciones que contiene se explican a continuación:

    - scheduler_init: Se encarga de inicializar las variables de tarea en curso y tarea futura así como tambien imprimir títulos en pantalla, cargar el registro "ltr" y encender las interrupciones. Termina en un loop de halt para esperar el tiempo dedicado a la presentación del programa.
    
    - m_scheduler: Llama a las diferentes partes del scheduler y es la función llamada por el timer al momento de cumplirse el tiempo de timer tick.
    
    - save_old_context: Guarda el contexto de la tarea saliente.
    
    - load_new_context: Carga el contexto de la tarea entrante.
    
    - scheduler_logic: Define la política de cambio de taréas del scheduler.
    
    - contexts_init: Función que es llamada por "scheduler_init". Se encarga de cargar los contextos por primera vez, tanto de tareas como el de Kernel (en realidad carga la TSS que luego es cargada en ltr).
    
    - reset_contexts: Una vez terminadas las tareas (o sea que llegaron a halt) tienen que ser reseteados sus contextos. De esto se encarga la función citada.

* ###### screen.asm: 
    Este archivo contiene todo el código encargado de mostrar en pantalla las letras y números requeridos en el proyecto.

* ###### task1.asm, task2.asm, task3.asm: 
    Son las tareas administradas por el scheduler. Task1 y task2 tienen sumas que se implementan mediante SIMD y tasy3 simplemente se pone en halt (tarea idle).

* ###### timer.asm: 
    Aquí se encuentran los contadores del sistema. Ambos contadores de tiempo de las tareas y el de la pantalla de inicio son controlados por el código que él contiene.

### Funcionamiento del scheduler

##### Cargado de contexto entrante a memoria

##### Guardado de contexto saliente

##### Politica del scheduler

### Pantalla

### Teclado

##### Buffer de teclado

##### Guardado de caractes en la lista

### Paginación

##### Mapa de paginación

|      Sección        |  Dirección física inicial  | Dirección lineal inicial | Indice en Directorio de Paginas (1° Tabla de Pagina) | Indice en Tabla de Paginas (1° Pagina) | 
|:-------------------:|:------------------:|:----------------:|:--------------------:|:---------------:|
|ISR                  |     00000000h      |     00000000h    |         0x000        |      0x000      |
|Video                |     000B8000h      |     00010000h    |         0x000        |      0x010      |
|Tablas de sistema    |     00100000h      |     00100000h    |         0x000        |      0x100      |
|Tablas de paginación |     00110000h      |     00110000h    |         0x000        |      0x110      |
|Núcleo               |     00200000h      |     01200000h    |         0x004        |      0x200      |
|Datos                |     00202000h      |     01202000h    |         0x004        |      0x202      |
|Tabla de dígitos     |     00210000h      |     01210000h    |         0x004        |      0x210      |
|TEXT Tarea 1         |     00300000h      |     01300000h    |         0x004        |      0x300      |
|BSS Tarea 1          |     00301000h      |     01301000h    |         0x004        |      0x301      |
|DATA Tarea 1         |     00302000h      |     01302000h    |         0x004        |      0x302      |
|TEXT Tarea 2         |     00310000h      |     01310000h    |         0x004        |      0x310      |
|BSS Tarea 2          |     00311000h      |     01311000h    |         0x004        |      0x311      |
|DATA Tarea 2         |     00312000h      |     01312000h    |         0x004        |      0x312      |
|TEXT Tarea 3         |     00320000h      |     01320000h    |         0x004        |      0x320      |
|BSS Tarea 3          |     00321000h      |     01321000h    |         0x004        |      0x321      |
|DATA Tarea 3         |     00322000h      |     01322000h    |         0x004        |      0x322      |
|Pila Nucleo          |     1FF08000h      |     1FF08000h    |         0x07F        |      0x308      |
|Pila Tarea 3         |     1FFFD000h      |     00713000h    |         0x001        |      0x313      |
|Pila Tarea 2         |     1FFFE000h      |     00713000h    |         0x001        |      0x313      |
|Pila Tarea 1         |     1FFFF000h      |     00713000h    |         0x001        |      0x313      |
|Secuencia inic. ROM  |     FFFF0000h      |     FFFF0000h    |         0x3FF        |      0x3F0      |
|Vector de reset      |     FFFFFFF0h      |     FFFFFFF0h    |         0x3FF        |      0x3FF      |
