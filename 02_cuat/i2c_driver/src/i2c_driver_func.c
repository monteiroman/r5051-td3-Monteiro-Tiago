
/*____________________________________________________________________________*/
/*                                                                            */
/*                      Module registering functions                          */
/*                                                                            */
/*____________________________________________________________________________*/


static int m_i2c_probe(struct platform_device *pdev) {
    uint32_t auxValue;

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

        return 1;
    }


    // SCL Pin (Page 1515)
    //  0x3B = 111011b 
    //  => Fast | Reciever Enable | Pullup | Pullup/pulldown disabled | I2C2_SCL
    iowrite32(0x3B, controlModule_base + CONF_UART1_RTSN_OFFSET);   // se puede probar con 0x33
      
    // SDA Pin
    //  0x3B = 111011b 
    //  => Fast | Reciever Enable | Pullup | Pullup/pulldown disabled | I2C2_SCL
    iowrite32(0x3B, controlModule_base + CONF_UART1_CTSN_OFFSET);   // se puede probar con 0x33


    // >------------------- Configuring Virtual IRQ -------------------< //
    if((virt_irq = platform_get_irq(pdev, 0)) < 0){

        print_error_msg_wo_status("PROBE", __FILE__, (char*)__FUNCTION__,
            __LINE__);

        //Requested resources rollback. 
        iounmap(i2c2_base);
        iounmap(cmPer_base);
        iounmap(controlModule_base);

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
    iowrite32(0x1e, i2c2_base + I2C_SA);


    iowrite32( I2C_IRQSTATUS_XRDY, i2c2_base + I2C_IRQENABLE_SET); 
    iowrite32( I2C_IRQSTATUS_XRDY , i2c2_base + I2C_IRQSTATUS_RAW); 

    // configure register -> ENABLE & MASTER & RX & STOP
    // iowrite32(0x8400, i2c2_base + I2C_CON);
    iowrite32(0x8601, i2c2_base + I2C_CON);

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


