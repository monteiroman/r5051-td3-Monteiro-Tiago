
/*____________________________________________________________________________*/
/*                                                                            */
/*                      Module registering functions                          */
/*                                                                            */
/*____________________________________________________________________________*/

irqreturn_t driver_isr(int irq, void *devid) {
    return IRQ_HANDLED;
}

static int m_i2c_probe(struct platform_device *pdev) {
    int status = 0;
    struct resource *mem = NULL;

    dev_info(&pdev->dev, "Initializing driver controller.\n");

    if ((state.irq = platform_get_irq(pdev, 0)) < 0) {
        return state.irq;
    }

    mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    state.base = devm_ioremap_resource(&pdev->dev, mem);
    if (IS_ERR(state.base)) {
        return PTR_ERR(state.base);
    }

    if ((status = of_property_read_u32(pdev->dev.of_node, "clock-frequency",
                                     &state.freq)) != 0) {
        state.freq = 100000; // default to 100000 Hz
    }

    if ((status = devm_request_irq(&pdev->dev, state.irq, driver_isr,//usar//
                                 IRQF_NO_SUSPEND, pdev->name, NULL)) != 0) {
        return status;
    }

    dev_info(&pdev->dev, "Driver controller successfully initialized.\n");

    return 0;
}

static int m_i2c_remove(struct platform_device *pdev){

    dev_info(&pdev->dev, "Removing driver controller\n");
    dev_info(&pdev->dev, "Driver controller successfully removed.\n");
    
    return 0;
}


