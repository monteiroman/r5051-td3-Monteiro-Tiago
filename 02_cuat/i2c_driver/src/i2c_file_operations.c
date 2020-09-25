/*____________________________________________________________________________*/
/*    File operations for the i2c driver.                                     */
/*        Functions:                                                          */
/*              m_i2c_open                                                    */
/*              m_i2c_close                                                   */
/*              m_i2c_read                                                    */
/*              m_i2c_write                                                   */
/*____________________________________________________________________________*/

irqreturn_t driver_isr(int irq, void *devid) {
//    uint32_t irq_status;
    uint32_t auxOA, auxSA;

    print_info_msg("IRQ", __FILE__, "Inside IRQ!!!!!!!!!!!!!!!.");

    // clear all flags
    // irq_status = ioread32(i2c2_base + I2C_IRQSTATUS);
    // irq_status |= 0x3E;
    // iowrite32(irq_status, i2c2_base + I2C_IRQSTATUS);

    iowrite32( I2C_IRQSTATUS_XRDY , i2c2_base + I2C_IRQENABLE_CLR);

    auxOA = ioread32(i2c2_base + I2C_OA);
    auxSA = ioread32(i2c2_base + I2C_SA);
    printk(KERN_INFO "[I]: OwnAdress: %d ---SlaveAdress: %d.\n", auxOA, auxSA);

    //iowrite32(0x8601, i2c2_base + I2C_CON);


    return (irqreturn_t)IRQ_HANDLED;
}

static int m_i2c_open(struct inode *inode, struct file *file) {
    return 0;
}

static int m_i2c_release(struct inode *inode, struct file *file) {
    return 0;
}

static ssize_t m_i2c_read(struct file *m_file, char __user *buffer, size_t size,
     loff_t *offset) {
    return 0;
}

static ssize_t m_i2c_write(struct file *m_file, const char *buffer, size_t len,
     loff_t *offset){
    return 0;
}

// Struct that defines my device operations. 
struct file_operations mFileOps =
{
   .owner = THIS_MODULE,
   .open = m_i2c_open,
   .release = m_i2c_release,
   .read = m_i2c_read,
   .write = m_i2c_write,
};
