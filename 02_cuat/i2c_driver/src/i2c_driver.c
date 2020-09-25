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

    // Print info message.
    print_info_msg("INIT", __FILE__, "Initializing module...");
    
    // Allocates a range of char device numbers. The major number will be chosen
    //  dynamically, and returned (along with the first minor number) in 
    //  state.m_i2c_device_type. Returns zero or a negative error code.
    // https://manned.org/alloc_chrdev_region.9
    if((status = alloc_chrdev_region(&state.m_i2c_device_type, BASE_MINOR,
        MINOR_COUNT, DEVICE_NAME)) < 0){
        
        print_error_msg_w_status("INIT", __FILE__, (char*)__FUNCTION__, 
            __LINE__, status);

        return status;
    }

   // Creates a struct class pointer that can then be used in calls to 
   //   device_create.
   // Note, the pointer created here is to be destroyed when finished by
   //   making a call to class_destroy.
   // https://manned.org/class_create
   if((state.m_i2c_class = class_create(THIS_MODULE, CLASS_NAME)) == NULL){

        print_error_msg_wo_status("INIT", __FILE__, (char*)__FUNCTION__,
            __LINE__);
    
        //Requested resources rollback. 
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return EFAULT;
    }

    // This function can be used by char device classes. A struct device will
    //  be created in sysfs, registered to the specified class.
    // Returns struct device pointer on success, or ERR_PTR on error.
    // https://manned.org/device_create.9
    if((device_create(state.m_i2c_class, DEVICE_PARENT, state.m_i2c_device_type,
        DEVICE_DATA, NAME_SHORT)) == NULL){

        print_error_msg_wo_status("INIT", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback. 
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return EFAULT;
    }

    // Initializes state.m_i2c_cdev, remembering mFileOps, making it ready to
    //  add to the system with cdev_add.
    // https://manned.org/cdev_init.9
    cdev_init(&state.m_i2c_cdev, &mFileOps);

    // Adds the device represented by state.m_i2c_cdev to the system, making it
    //  live immediately. A negative error code is returned on failure.
    // https://manned.org/cdev_add.9
    if((status  = cdev_add(&state.m_i2c_cdev, state.m_i2c_device_type,
        MINOR_COUNT)) < 0){

        print_error_msg_w_status("INIT", __FILE__, (char*)__FUNCTION__,
            __LINE__, status);

        //Requested resources rollback.
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return status;
    }

    // Register platform driver to link the device tree with the driver module.
    // https://manned.org/platform_driver_register.9
    if((status = platform_driver_register(&m_i2c_pdriver)) < 0){

        print_error_msg_w_status("INIT", __FILE__, (char*)__FUNCTION__, 
            __LINE__, status);

        //Requested resources rollback. 
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return status;      
    }

    // Print info message.
    print_info_msg("INIT", __FILE__, "Module successfully registered!!");
    printk(KERN_INFO 
        "[I]: INIT | File: %s | Msg: Major number: %d, Minor number %d.\n", 
        __FILE__, MAJOR(state.m_i2c_device_type),
        MINOR(state.m_i2c_device_type));

    return status;
}

static void __exit i2c_exit(void){

    // Print info message.
    print_info_msg("EXIT", __FILE__, "Closing module...");

    //Requested resources rollback. 
    cdev_del(&state.m_i2c_cdev);
    device_destroy(state.m_i2c_class, state.m_i2c_device_type);
    class_destroy(state.m_i2c_class);
    unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);
    platform_driver_unregister(&m_i2c_pdriver);

    print_info_msg("EXIT", __FILE__, "Module successfully closed.");
}


/*____________________________________________________________________________*/

/*____________________________________________________________________________*/

module_init(i2c_init);
module_exit(i2c_exit);
