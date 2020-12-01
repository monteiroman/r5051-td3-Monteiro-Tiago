#include "../inc/i2c_driver.h"

#include "i2c_misc_func.c"
#include "i2c_file_operations.c"
#include "i2c_driver_func.c"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Monteiro Tiago (Leg.1420355)");
MODULE_DESCRIPTION("I2C Driver");


/*____________________________________________________________________________*/
/* Usefull links:                                                             */
/*      https://manned.org/                                                   */
/*      https://www.fsl.cs.sunysb.edu/kernel-api/                             */
/*____________________________________________________________________________*/

// The "compatible" char string that links the Device Tree and Device Driver.
static const struct of_device_id driver_of_match[] = {   
    { .compatible = "Monteiro.INC,Driver-i2c_v0" },
    { },
};

static struct platform_driver m_i2c_pdriver ={
    .probe  = m_i2c_probe,
    .remove = m_i2c_remove,
    .driver =
    {
        .name = "Monteiro_Tiago-i2c",
        .of_match_table = of_match_ptr(driver_of_match),
    },
};


/*____________________________________________________________________________*/
/*                                                                            */
/*                          Init and Exit functions                           */
/*                                                                            */
/*____________________________________________________________________________*/

static int __init i2c_init(void){
    int status = 0;

    // Register platform driver to link the device tree with the driver module.
    // https://manned.org/platform_driver_register.9
    if((status = platform_driver_register(&m_i2c_pdriver)) >= 0){

        print_error_msg_w_status("   INIT    ", __FILE__, (char*)__FUNCTION__, 
            __LINE__, status);

        return status;      
    }

    // Print info message.
    print_info_msg("   INIT    ", __FILE__, "Module successfully registered!!");
    printk(KERN_INFO 
      "[I]:    INIT     | File: %s | Msg: Major number: %d, Minor number %d.\n", 
        __FILE__, MAJOR(state.m_i2c_device_type),
        MINOR(state.m_i2c_device_type));

    return status;
}

static void __exit i2c_exit(void){

    // Print info message.
    print_info_msg("   EXIT    ", __FILE__, "Closing module...");

    //Requested resources rollback. 
    cdev_del(&state.m_i2c_cdev);
    device_destroy(state.m_i2c_class, state.m_i2c_device_type);
    class_destroy(state.m_i2c_class);
    unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);
    platform_driver_unregister(&m_i2c_pdriver);

    print_info_msg("   EXIT    ", __FILE__, "Module successfully closed.");
}


/*____________________________________________________________________________*/
/*                                                                            */
/*                              Caller methods                                */
/*                                                                            */
/*____________________________________________________________________________*/

module_init(i2c_init);
module_exit(i2c_exit);
