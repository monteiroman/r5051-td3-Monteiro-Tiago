### Scripts secundarios usados en el proyecto
Para el uso de los scripts de este proyecto se debe ejecutar
    sudo apt-get install sshpass.
Estos scripts se utilizaron para hacer mas simple la conección a la BBB durante los días de trabajo.

* **scp_BBB**: Se encarga de pasar archivos desde y hacia la BBB con valores por defecto que permiten hacer el trabajo mas fácil.

* **ssh_BBB**: Se encarga de conectar la PC a la BBB con valores por defecto, también puede apagar la BBB y setear la hora de la placa para poder compilar en ella. Este script necesita un poco mas de configuración. Para poder apagar la BBB y setear su hora hay que editar el archivo:

        /etc/sudoers

    poniendo la siguiente linea al final:

        debian ALL=NOPASSWD: /sbin/halt, /sbin/reboot, /sbin/poweroff, /bin/date

    Esto permite ejecutar los comandos **sudo poweroff** y **date -s** sin tener que poner la clave de root.
    Para el caso de la fecha hay que agregar una configuración mas. Se debe setear la zona horaria en GMT-3 con el comando:

        sudo timedatectl set-timezone Etc/GMT+3

    Es raro el **+** en vez de **-** pero están invertidos a la hora de setear.

#### Acceso
Para poder acceder desde cualquier lugar a estos scripts agregar el path de los mismos a .bashrc, de la siguiente manera: 
Abrir el archivo __.bashrc__ con: 
    
    nano ~/.bashrc

Agregar al final:
    
    export PATH=$PATH:/ruta_a_los_scripts

Reiniciar la terminal.

#### Notas
Cada script viene con su texto de ayuda en la opción __-h__.

#### [Volver al Readme principal](/02_cuat/README.md)