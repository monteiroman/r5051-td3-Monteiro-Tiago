
/*____________________________________________________________________________*/
/*                                                                            */
/*                      Module registering functions                          */
/*                                                                            */
/*____________________________________________________________________________*/


static int m_i2c_probe(struct platform_device *pdev) {
    uint32_t auxValue;
    uint8_t ira_reg_m_value, irb_reg_m_value, irc_reg_m_value;
    uint8_t value[1];
    int status = 0;

    // >-------------------- Initializing Chdev -----------------------< //
    //                   CLASS_NAME   "i2c_class"                        //
    //                   DEVICE_NAME  "i2c_TM"                           //
    // Print info message.
    print_info_msg("   INIT    ", __FILE__, "Initializing module...");
    
    // Allocates a range of char device numbers. The major number will be chosen
    //  dynamically, and returned (along with the first minor number) in 
    //  state.m_i2c_device_type. Returns zero or a negative error code.
    // https://manned.org/alloc_chrdev_region.9
    if((status = alloc_chrdev_region(&state.m_i2c_device_type, BASE_MINOR,
        MINOR_COUNT, DEVICE_NAME)) < 0){
        
        print_error_msg_w_status("   INIT    ", __FILE__, (char*)__FUNCTION__, 
            __LINE__, status);

        return status;
    }

   // Creates a struct class pointer that can then be used in calls to 
   //   device_create.
   // Note, the pointer created here is to be destroyed when finished by
   //   making a call to class_destroy.
   // https://manned.org/class_create
   if((state.m_i2c_class = class_create(THIS_MODULE, CLASS_NAME)) == NULL){

        print_error_msg_wo_status("   INIT    ", __FILE__, (char*)__FUNCTION__,
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

        print_error_msg_wo_status("   INIT    ", __FILE__, (char*)__FUNCTION__,
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

        print_error_msg_w_status("   INIT    ", __FILE__, (char*)__FUNCTION__,
            __LINE__, status);

        //Requested resources rollback.
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        return status;
    }


    // >-------------------- Initializing Driver ----------------------< //

    dev_info(&pdev->dev, "Initializing driver controller.\n");
    // Configuration steps at:                                           //
    //    SPRUH73Q – October 2011 – Revised December 2019 (Page 4583)    //

    // Maps the memory mapped IO for a given device_node : the device whose io
    //  range will be mapped : index of the io range.
    // Returns a pointer to the mapped memory.
    // https://docs.huihoo.com/doxygen/linux/kernel/3.7/of_2address_8c.html
    i2c2_base = of_iomap(pdev->dev.of_node, 0);


    // >------------- Initializing CM_PER_I2C2_CLKCTRL ----------------< //
    //                          Page 1270                                //
    //             This register manages the I2C2 clocks.                //

    // ioremap - Maps bus memory into CPU space.
    // Maps CM_PER register from physical to logical address.
    // https://manned.org/ioremap.9
    if((cmPer_base = ioremap(CM_PER, CM_PER_LEN)) == NULL){

        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback.
        iounmap(i2c2_base);
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT); 

        return 1;
    }

    // Enable clock.
    // ioread32 - Reads from I/O memory.
    // iowrite32 - Writes to I/O memory.
    auxValue = ioread32(cmPer_base + CM_PER_I2C2_CLKCTRL_OFFSET);
    auxValue |= 0x02;
    iowrite32(auxValue, cmPer_base + CM_PER_I2C2_CLKCTRL_OFFSET);

    // Wait until the clock is ready.
    msleep(10);

    // Check if CM PER is correctly configured.
    auxValue = ioread32(cmPer_base + CM_PER_I2C2_CLKCTRL_OFFSET);
    if((auxValue & 0x00000003) != 0x02){

        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback.
        iounmap(i2c2_base);
        iounmap(cmPer_base);
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT); 
        
        return 1;
    }


    // >--------------- Configuring the CONTROL MODULE ----------------< //
    //                            Page 1448                              //

    // Maps CONTROL_MODULE register from physical to logical address.
    if((controlModule_base = ioremap(CONTROL_MODULE, CONTROL_MODULE_LEN)) 
        == NULL){
        
        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback.
        iounmap(i2c2_base);
        iounmap(cmPer_base);
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT); 

        return 1;
    }


    // SCL Pin (Page 1515)
    //  0x3B = 111011b 
    //  => Fast | Reciever Enable | Pullup | Pullup/pulldown disabled | I2C2_SCL
    iowrite32(0x3B, controlModule_base + CONF_UART1_RTSN_OFFSET);
      
    // SDA Pin
    //  0x3B = 111011b 
    //  => Fast | Reciever Enable | Pullup | Pullup/pulldown disabled | I2C2_SCL
    iowrite32(0x3B, controlModule_base + CONF_UART1_CTSN_OFFSET);


    // >------------------- Configuring Virtual IRQ -------------------< //
    if((virt_irq = platform_get_irq(pdev, 0)) < 0){

        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback.
        iounmap(i2c2_base);
        iounmap(cmPer_base);
        iounmap(controlModule_base);
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT); 

        return 1;         
    }

    if(request_irq(virt_irq, (irq_handler_t) driver_isr, IRQF_TRIGGER_RISING, 
        DEVICE_NAME, NULL)){

        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback.
        iounmap(i2c2_base);
        iounmap(cmPer_base);
        iounmap(controlModule_base);
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT); 
        
        return 1;
    }


    // >------------------ Setting up I2C Registers -------------------< //
    // Disable I2C2.
    iowrite32(0x0000, i2c2_base + I2C_CON);

    // Prescaler configured at 24Mhz
    iowrite32(0x01, i2c2_base + I2C_PSC);

    // Configure SCL to 1MHz
    iowrite32(0x35, i2c2_base + I2C_SCLL);
    iowrite32(0x37, i2c2_base + I2C_SCLH);

    // Random Own Address
    iowrite32(0x77, i2c2_base + I2C_OA);

    // I2C_SYSC has 0h value on reset, don't need to be configured.

    // Slave Address
    iowrite32(LSM303_MAGNETIC_ADDR, i2c2_base + I2C_SA);     //magnetrometro
    
    // configure register -> ENABLE & MASTER & RX & STOP
    // iowrite32(0x8400, i2c2_base + I2C_CON);
    iowrite32(0x8600, i2c2_base + I2C_CON);


    // >----------------- Checking compatible device ------------------< //
    // The LSM303HCL does not have WOAMI register so I need to check the //
    // default values of three registers. IRA_REG_M, IRB_REG_M and       //
    // IRc_REG_M.                                                        //

    // IRA register
    value[0] = LSM303_REGISTER_MAG_IRA_REG_M;
    m_i2c_writeBuffer(value, sizeof(value));
    ira_reg_m_value = m_i2c_readByte();

    // IRB register
    value[0] = LSM303_REGISTER_MAG_IRB_REG_M;
    m_i2c_writeBuffer(value, sizeof(value));
    irb_reg_m_value = m_i2c_readByte();

    // IRC register
    value[0] = LSM303_REGISTER_MAG_IRC_REG_M;
    m_i2c_writeBuffer(value, sizeof(value));
    irc_reg_m_value = m_i2c_readByte();

    if(ira_reg_m_value != 0x48 || irb_reg_m_value != 0x34 || 
                                            irc_reg_m_value != 0x33){
        //Requested resources rollback. 
        free_irq(virt_irq, NULL);
        iounmap(i2c2_base);
        iounmap(cmPer_base);
        iounmap(controlModule_base);
        cdev_del(&state.m_i2c_cdev);
        device_destroy(state.m_i2c_class, state.m_i2c_device_type);
        class_destroy(state.m_i2c_class);
        unregister_chrdev_region(state.m_i2c_device_type, MINOR_COUNT);

        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);
        print_info_msg(" I2C_PROBE ", __FILE__, "No LSM303DHLC connected.");

        return 1;            
    }

    dev_info(&pdev->dev, "Driver controller successfully initialized.\n");

    return 0;
}

static int m_i2c_remove(struct platform_device *pdev){

    dev_info(&pdev->dev, "Removing driver controller\n");
    
    //Requested resources rollback. 
    free_irq(virt_irq, NULL);
    iounmap(i2c2_base);
    iounmap(cmPer_base);
    iounmap(controlModule_base);
    
    dev_info(&pdev->dev, "Driver controller successfully removed.\n");
    
    return 0;
}


