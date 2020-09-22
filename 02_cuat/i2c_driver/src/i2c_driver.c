#include "../inc/i2c_driver.h"



MODULE_LICENSE("GPL");
MODULE_AUTHOR("Monteiro Tiago (Leg.1420355)");
MODULE_DESCRIPTION("I2C Driver");


/*EL COMPATIBLE QUE ENCUENTRA EL KERNEL EN EL DD Y EL DTREE*/
static const struct of_device_id driver_of_match[] = {   
  { .compatible = "Monteiro.INC,Driver-i2c_v0" },
  { },
};

static struct platform_driver m_i2c_pdriver =
   {
      .probe  = m_i2c_probe,
      .remove = m_i2c_remove,
      .driver =
      {
        .name = "Monteiro_Tiago-i2c",
        .of_match_table = of_match_ptr(driver_of_match),
      },
   };


/*____________________________________________________________________________*/

/*____________________________________________________________________________*/

static int m_i2c_probe(struct platform_device *pdev) {
  int status = 0;
  struct resource *mem = NULL;

  dev_info(&pdev->dev, "Initializing driver controller\n");

  if ((state.irq = platform_get_irq(pdev, 0)) < 0) {
    return state.irq;
  }

  mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
  state.base = devm_ioremap_resource(&pdev->dev, mem);
  if (IS_ERR(state.base)) {
    return PTR_ERR(state.base);
  }

  if ((status = of_property_read_u32(pdev->dev.of_node,
                                     "clock-frequency",
                                     &state.freq)) != 0) {
    state.freq = 100000; // default to 100000 Hz
  }

  if ((status = devm_request_irq(&pdev->dev, state.irq, driver_isr,//usar//
                                 IRQF_NO_SUSPEND, pdev->name, NULL)) != 0) {
    return status;
  }
}

static int m_i2c_remove(struct platform_device *pdev)
{
    dev_info(&pdev->dev, "Removing driver\n");
    dev_info(&pdev->dev, "Driver removed\n");
}


/*____________________________________________________________________________*/

/*____________________________________________________________________________*/

static int __init i2c_init(void){
    int status = 0;

    // Print info message.
    print_info_msg("INIT", __FILE__, "Initializing module...");
    
    // alloc char device region
    if((status = alloc_chrdev_region(&state.m_i2c_device_type, BASE_MINOR,
        MINOR_COUNT, DEVICE_NAME)) < 0){
        
        print_error_msg_w_status("INIT", __FILE__, __FUNCTION__, __LINE__,
            status);

        return status;
    }

   // Create device class
   if((state.m_i2c_class = class_create(THIS_MODULE, CLASS_NAME)) == NULL){

        print_error_msg_wo_status("INIT", __FILE__, __FUNCTION__, __LINE__);
    
        //Requested resources rollback 
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return EFAULT;
    }


    // create device and relate region with class
    if((device_create(state.m_i2c_class, DEV_PARENT, state.m_i2c_device_type,
        DEV_DATA, NAME_SHORT)) == NULL){

        print_error_msg_wo_status("INIT", __FILE__, __FUNCTION__, __LINE__);

        //Requested resources rollback 
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return EFAULT;
    }


    // initialize the char device (type, file operations)
    cdev_init(&state.m_i2c_cdev, &mFileOps);


    // add char device
    if((status  = cdev_add(&state.m_i2c_cdev, state.m_i2c_device_type,
        MINOR_COUNT)) < 0){

        print_error_msg_w_status("INIT", __FILE__, __FUNCTION__, __LINE__,
            status);

        //Requested resources rollback 
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

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
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return status;      
    }

    print_info_msg("INIT", __FILE__, "Module successfully registered!!");
    printk(KERN_INFO 
        "[I]: INIT | File: %s | Msg: major number: %d, minor number %d\n", 
        __FILE__, MAJOR(state.m_i2c_device_type),
        MINOR(state.m_i2c_device_type));

    return status;
}

static void __exit i2c_exit(void){

    print_info_msg("EXIT", __FILE__, "Closing module...");

    cdev_del(&state.m_i2c_cdev);
    device_destroy(state.m_i2c_class, i2c_dev);
    class_destroy(state.m_i2c_class);
    unregister_chrdev_region(i2c_dev, MINOR_COUNT);
    platform_driver_unregister(&m_i2c_pdriver);

    print_info_msg("EXIT", __FILE__, "Module successfully closed");
    
}


/*____________________________________________________________________________*/

/*____________________________________________________________________________*/

// Relate functions
module_init(i2c_init);
module_exit(i2c_exit);
