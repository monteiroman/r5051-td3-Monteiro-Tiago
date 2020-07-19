## Scheduler

#### Funcionamiento del scheduler

Es el encargado de manejar la multiplexación en tiempo de las tareas. Cada tarea está un tiempo limitado, determinado por el timertick, ejecutando código.

![Alt text](/01_cuat/Readme_docs/img/scheduler.png )

La imagen de arriba es del profesor Dario Alpern.



Se intentó tener en cuenta cualquier posibilidad que surja en tiempo de ejecución del programa, de esta manera el scheduler es capaz de recibir tanto una pila de supervisor así como también una de usuario (con todo lo que ello conlleva). La verificación de cómo se tiene que comportar se hace mirando el privilegio del selector de segmento de código que viene en la pila al momento de la interrupción.

El primer paso en el scheduler es setear los contextos con los valores de inicio de cada tarea, es por esto que la función "Main" (en bios.asm) llama a la función "scheduler_init" por medio de un jump cuando termina de iniciar el microprocesador. Esta funcion "scheduler_init" entonces se encarga de setear las variables que indican la tarea futura y la tarea en ejecución con valores de inicio, inicia también los contextos de las tareas con los valores correspondientes, llama a la función que imprime el titulo y mi nombre en pantalla, inicia el registro "tr" y finalmente se queda a la espera unos segundos para dar comienzo al cambio de tareas.

La tss que se carga en el descriptor al que apunta "tr" tiene solo la dirección del selector de datos con privilegio 0 para "ss" y la dirección lineal de la pila con privilegio 0 para las tareas que, debido a que tienen las tres la misma dirección lineal, no es necesario cambiar una vez que se inicia el sistema.



#### Politica del scheduler

En pos de que una tarea no bloquee a otra, en cada timertick el scheduler va a pasar de una tarea a la otra obligadamente, siempre y cuando las condiciones impuestas por el proyecto estén dadas. Es decir, si se está ejecutando la tarea 1 debido a que ya se cumplió su tiempo de espera (100ms) y tambien se tiene que ejecutar la tarea 2 porque su flag está en uno (cada 200ms), supongamos que la tarea 1 no terminó de ejecutar su suma en los 10ms que le corresponde, el scheduler ejecutará la tarea 2 sin importar que la tarea 1 no haya terminado. Esto será así hasta que se termine el tiempo de la tarea 2 (10ms) volviendo a la tarea 1 si fuera necesario.