### Device tree
El archivo **.dtb** es el binario que va en **/boot/dtbs/4.19.94-ti-r42**.
El archivo **.dts** es el archivo de texto que tengo que editar. En él hay que cambiar el 

* Para decompilar el .dtb:
    
        dtc -I dtb -O dts am335x-boneblack.dtb -o am335x-boneblack.dts

* Para compilar el .dts:
    
        dtc -I dts -O dtb am335x-boneblack.dts -o am335x-boneblack.dtb

Con **"ls /proc/device-tree/ocp/"** veo si mi device tree está bien hecho.

#### Backup de Device Tree
Dentro de este directorio, la carpeta **Secure_Device_Tree** tiene un backup del device tree por las dudas y la carpeta **Project_Device_Tree** tiene el device tree del proyecto.

Se modificaron las lineas:

    i2c@4819c000 {
                compatible = "ti,omap4-i2c";
                #address-cells = < 0x01 >;
                #size-cells = < 0x00 >;
                ti,hwmods = "i2c3";
                reg = < 0x4819c000 0x1000 >;
                interrupts = < 0x1e >;
                status = "okay";
                pinctrl-names = "default";
                pinctrl-0;
                clock-frequency = < 0x186a0 >;
                phandle = < 0xae >;

Por:

    Monteiro_Tiago-i2c@4819c000 {
                compatible = "Monteiro.INC,Driver-i2c_v0";
                #address-cells = < 0x01 >;
                #size-cells = < 0x00 >;
                ti,hwmods = "Monteiro_Tiago-i2c3";
                reg = < 0x4819c000 0x1000 >;
                interrupts = < 0x1e >;
                status = "okay";
                pinctrl-names = "default";
                pinctrl-0;
                clock-frequency = < 0x186a0 >;
                phandle = < 0xae >;

#### Para hacer andar el device tree
Editar **/boot/uEnv.txt**

Se comenta la siguiente línea:

    #enable_uboot_overlays=1

Se eliminan los comentarios de las siguientes líneas:

    disable_uboot_overlay_emmc=1
    disable_uboot_overlay_video=1
    disable_uboot_overlay_audio=1
    disable_uboot_overlay_wireless=1
    disable_uboot_overlay_adc=1
