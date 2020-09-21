#include "../inc/i2c_driver.h"



MODULE_LICENSE("GPL");
MODULE_AUTHOR("Monteiro Tiago (Leg.1420355)");
MODULE_DESCRIPTION("I2C Driver");


/*____________________________________________________________________________*/

/*____________________________________________________________________________*/

static int __init i2c_init(void){
    int status = 0;

    // Print info message.
    print_info_msg("INIT", __FILE__, "Initializing module...");
    
    // alloc char device region
    if((status = alloc_chrdev_region(&state.m_i2c_device_type, MINORBASE,
        MINORCOUNT, NAME)) < 0){
        
        print_error_msg_w_status("INIT", __FILE__, __FUNCTION__, __LINE__,
            status);

        return status;
    }

   // Create device class
   if((state.m_i2c_class = class_create(THIS_MODULE, CLASS)) == NULL){

        print_error_msg_wo_status("INIT", __FILE__, __FUNCTION__, __LINE__);
    
        //Requested resources rollback 
        unregister_chrdev_region(state.m_i2c_device_type, MINORCOUNT);

        return EFAULT;
    }


    // create device and relate region with class
    if((device_create(state.m_i2c_class, DEV_PARENT, state.m_i2c_device_type,
        DEV_DATA, NAME_SHORT)) == NULL){

        print_error_msg_wo_status("INIT", __FILE__, __FUNCTION__, __LINE__);

        //Requested resources rollback 
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINORCOUNT);

        return EFAULT;
    }


    // initialize the char device (type, file operations)
    cdev_init(&state.m_i2c_cdev, &mFileOps);


    // add char device
    if((status  = cdev_add(&state.m_i2c_cdev, state.m_i2c_device_type,
        MINORCOUNT)) < 0){

        print_error_msg_w_status("INIT", __FILE__, __FUNCTION__, __LINE__,
            status);

        //Requested resources rollback 
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINORCOUNT);

        return status;
    }


    // register platform driver to relate the device tree with the driver module
    if((status = platform_driver_register(&m_i2c_pdriver)) < 0){

        print_error_msg_w_status("INIT", __FILE__, __FUNCTION__, __LINE__,
            status);

        //Requested resources rollback 
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINORCOUNT);

        return status;      
    }

    print_info_msg("INIT", __FILE__, "Module successfully registered!!");
    printk(KERN_INFO 
        "[I]: INIT | File: %s | Msg: major number: %d, minor number %d\n", 
        __FILE__, MAJOR(state.m_i2c_device_type),
        MINOR(state.m_i2c_device_type));

    return status;
}


/*____________________________________________________________________________*/

/*____________________________________________________________________________*/

static void __exit i2c_exit(void){

    print_info_msg("EXIT", __FILE__, "Closing module...");

    cdev_del(&state.m_i2c_cdev);
    device_destroy(state.m_i2c_class, i2c_dev);
    class_destroy(state.m_i2c_class);
    unregister_chrdev_region(i2c_dev, MINORCOUNT);
    platform_driver_unregister(&m_i2c_pdriver);

    print_info_msg("EXIT", __FILE__, "Module successfully closed");
    
}

// Relate functions
module_init(i2c_init);
module_exit(i2c_exit);


