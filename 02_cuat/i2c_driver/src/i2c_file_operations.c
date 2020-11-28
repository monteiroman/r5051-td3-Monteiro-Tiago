/*____________________________________________________________________________*/
/*                                                                            */
/*                  I2C Read and Write byte functions                         */
/*                                                                            */
/*____________________________________________________________________________*/

void m_i2c_writeBuffer (uint8_t *writeData, int writeData_size){
    uint32_t i = 0;
    uint32_t aux_regValue = 0;
    uint32_t status = 0;

    // print_info_msg("WRITE_BYTE ", __FILE__, "Writing byte in i2c bus...");

    // Check irq status (occupied or free)
    aux_regValue = ioread32(i2c2_base + I2C_IRQSTATUS_RAW);

    while((aux_regValue >> 12) & 1){
       msleep(100);
       print_error_msg_wo_status("WRITE_BYTE ", __FILE__, (char*)__FUNCTION__,
            __LINE__);
       i++;

        if(i == 4){
            print_error_msg_wo_status("WRITE_BYTE ", __FILE__, 
                (char*)__FUNCTION__, __LINE__);

            return;
        }
    }

    // Load data to the variable of the irq.
    i2c_txData = writeData;
    i2c_txData_size = writeData_size;

    // Set the data length to 1 byte.
    iowrite32(i2c_txData_size, i2c2_base + I2C_CNT);

    // Set I2C_CON to Master transmitter.
    //  0000 0110 0000 0000 b = 0x600
    aux_regValue = ioread32(i2c2_base + I2C_CON);
    aux_regValue |= 0x600;
    iowrite32(aux_regValue, i2c2_base + I2C_CON);

    // Transmit data ready IRQ enabled status => Transmit data ready.
    iowrite32(I2C_IRQSTATUS_XRDY, i2c2_base + I2C_IRQENABLE_SET);

    // Start condition queried.
    aux_regValue = ioread32(i2c2_base + I2C_CON);
    aux_regValue |= I2C_CON_START;
    iowrite32(aux_regValue, i2c2_base + I2C_CON);

    // Wait transmission end.
    if((status = wait_event_interruptible(
        m_i2c_wk, m_i2c_wk_condition > 0)) < 0){

        m_i2c_wk_condition = 0;
        print_error_msg_wo_status("WRITE_BYTE ", __FILE__, (char*)__FUNCTION__,
            __LINE__);
       
        return;
    }

    m_i2c_wk_condition = 0;

    // Stop condition queried. (Must clear I2C_CON_STT).
    aux_regValue = ioread32(i2c2_base + I2C_CON);
    aux_regValue &= 0xFFFFFFFE;
    aux_regValue |= I2C_CON_STOP;
    iowrite32(aux_regValue, i2c2_base + I2C_CON);

    msleep(1);

    // print_info_msg("WRITE_BUFF ", __FILE__, 
        // "Write byte in i2c bus returns OK!");
}

uint8_t m_i2c_readByte(void){
    uint32_t i = 0;
    uint32_t aux_regValue = 0;
    uint32_t status = 0;
    uint8_t readData;

    // print_info_msg(" READ_BYTE ", __FILE__, "Reading byte from i2c bus...");

    // Check irq status (occupied or free).
    aux_regValue = ioread32(i2c2_base + I2C_IRQSTATUS_RAW);
    
    while((aux_regValue >> 12) & 1){
        msleep(100);
        print_error_msg_wo_status(" READ_BYTE ", __FILE__, (char*)__FUNCTION__,
            __LINE__);
        i++;

        if(i >= 4){
            print_error_msg_wo_status(" READ_BYTE ", __FILE__, 
                (char*)__FUNCTION__, __LINE__);

            return -1;
        }
    }

    // Set the data length to 1 byte.
    iowrite32(1, i2c2_base + I2C_CNT);

    // configure register -> ENABLE & MASTER & RX & STOP
    aux_regValue = 0x8400;
    iowrite32(aux_regValue, i2c2_base + I2C_CON);

    // Receive data ready IRQ enabled status => Receive data available.
    iowrite32(I2C_IRQSTATUS_RRDY, i2c2_base + I2C_IRQENABLE_SET);

    // Start condition queried. (Must clear I2C_CON_STP).
    aux_regValue = ioread32(i2c2_base + I2C_CON);
    aux_regValue &= 0xFFFFFFFC;
    aux_regValue |= I2C_CON_START;
    iowrite32(aux_regValue, i2c2_base + I2C_CON);

    // Wait reception end.
    if((status = wait_event_interruptible(
        m_i2c_wk, m_i2c_wk_condition > 0)) < 0){
            
        m_i2c_wk_condition = 0;
        print_error_msg_w_status(" READ_BYTE ", __FILE__, (char*)__FUNCTION__,
            __LINE__, status);

        return status;
    }

    m_i2c_wk_condition = 0;

    // Stop condition queried. (Must clear I2C_CON_STT).
    aux_regValue = ioread32(i2c2_base + I2C_CON);
    aux_regValue &= 0xFFFFFFFE;
    aux_regValue |= I2C_CON_STOP;
    iowrite32(aux_regValue, i2c2_base + I2C_CON);

    // Retrieve data.
    readData = i2c_rxData;

    msleep(1);

    // print_info_msg(" READ_BYTE ", __FILE__, 
        // "Read byte from i2c bus returns OK!");

    return readData;
}


/*____________________________________________________________________________*/
/*                                                                            */
/*                          Interruption Driver                               */
/*                                                                            */
/*____________________________________________________________________________*/

irqreturn_t driver_isr(int irq, void *devid, struct pt_regs *regs) {
    uint32_t irq_status;
    uint32_t aux_regValue;

    // print_info_msg("    IRQ    ", __FILE__, "New interruption.");

    irq_status = ioread32(i2c2_base + I2C_IRQSTATUS);

    // If it is a reception irq...
    if(irq_status & I2C_IRQSTATUS_RRDY){
        // print_info_msg("    IRQ    ", __FILE__, 
            // "-----> RX Interruption <-----");

        // Retrieve data.
        i2c_rxData = ioread8(i2c2_base + I2C_DATA);
       
        // Clear flags.
        // 0000 0000 0010 0111 b = 0x27
        aux_regValue = ioread32(i2c2_base + I2C_IRQSTATUS);
        aux_regValue |= 0x27;
        iowrite32(aux_regValue, i2c2_base + I2C_IRQSTATUS);

        // Disable rx interrupt.
        aux_regValue = ioread32(i2c2_base + I2C_IRQENABLE_CLR);
        aux_regValue |= I2C_IRQSTATUS_RRDY;
        iowrite32 (aux_regValue, i2c2_base + I2C_IRQENABLE_CLR);

        // Wake up read operation.
        m_i2c_wk_condition = 1;
        wake_up_interruptible(&m_i2c_wk);
    }
   
    // If it is a transmission irq...
    if(irq_status & I2C_IRQSTATUS_XRDY){
        // print_info_msg("    IRQ    ", __FILE__, 
            // "-----> TX Interruption <-----");

        // Write data
        iowrite8(i2c_txData[i2c_txData_byteCount], i2c2_base + I2C_DATA);

        i2c_txData_byteCount ++;

        if(i2c_txData_byteCount == i2c_txData_size){
            i2c_txData_byteCount = 0;

            // Clear flags.
            // 0000 0000 0011 0110 b = 0x36
            aux_regValue = ioread32(i2c2_base + I2C_IRQSTATUS);
            aux_regValue |= 0x36;
            iowrite32(aux_regValue, i2c2_base + I2C_IRQSTATUS);

            // Disable tx interrupt.
            aux_regValue = ioread32(i2c2_base + I2C_IRQENABLE_CLR);
            aux_regValue |= I2C_IRQSTATUS_XRDY;
            iowrite32 (aux_regValue, i2c2_base + I2C_IRQENABLE_CLR);

            // Wake up write operation.
            m_i2c_wk_condition = 1;
            wake_up_interruptible(&m_i2c_wk);

            // Clear all flags.
            // 0000 0000 0011 1110 b = 0x3E
            irq_status = ioread32(i2c2_base + I2C_IRQSTATUS);
            irq_status |= 0x3E;
            iowrite32(irq_status, i2c2_base + I2C_IRQSTATUS);    
        }
    }

    // print_info_msg("    IRQ    ", __FILE__, "IRQ handled OK!");

    return (irqreturn_t)IRQ_HANDLED;
}


/*____________________________________________________________________________*/
/*  File operations for the i2c driver.                                       */
/*        Functions:                                                          */
/*              m_i2c_open                                                    */
/*              m_i2c_release                                                 */
/*              m_i2c_read                                                    */
/*              m_i2c_write                                                   */
/*                                                                            */
/*  Usefull information:                                                      */
/*                   https://github.com/adafruit/Adafruit_LSM303              */
/*____________________________________________________________________________*/

static int m_i2c_open(struct inode *inode, struct file *file) {
    uint8_t writeBuffer[2];

    // >---------- Set accelerometer configuration registers ----------< //
    // Set the accel sensor address to be readed/written   
    iowrite32(LSM303_ACCELEROMETER_ADDR, i2c2_base + I2C_SA);

    // Set: 
    //      X, Y and Z enable, 
    //      Normal mode and 
    //      Normal / low-power mode (25 Hz).
    writeBuffer[0] = LSM303_REGISTER_ACCEL_CTRL_REG1_A;
    writeBuffer[1] = 0x37;    
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));

    // Set:
    //      Block data update: continuos update.
    //      Big/little endian data selection: data LSB @ lower address.
    //      Full-scale selection: +/- 2G.
    //      High resolution output mode: high resolution disable.
    //      Serial interface mode selection: 4-wire interface.
    writeBuffer[0] = LSM303_REGISTER_ACCEL_CTRL_REG4_A;
    writeBuffer[1] = 0x00;    
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    
    
    // >--------- Set magnetic sensor configuration registers ---------< //
    // Set the magnetic sensor address to be readed/written   
    iowrite32(LSM303_MAGNETIC_ADDR, i2c2_base + I2C_SA);   

    // Set: 
    //      temperature sensor disable, 
    //      minimum data output rate 15Hz. 
    //      [Bits 6, 5, 1 and 0 must be set to zero].
    writeBuffer[0] = LSM303_REGISTER_MAG_CRA_REG_M;
    writeBuffer[1] = 0x10;    
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));

    // Set:
    //      range to +-1.3 Gauss.
    //      [Bits 4 to 0 must be set to zero].
    writeBuffer[0] = LSM303_REGISTER_MAG_CRB_REG_M;
    writeBuffer[1] = 0x20;    
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));

    // Set:
    //      continuous-conversion mode.
    //      [Bits 2 to 7 must be set to zero].
    writeBuffer[0] = LSM303_REGISTER_MAG_MR_REG_M;
    writeBuffer[1] = 0x00;    
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));

    msleep(50);

    return 0;
}

static int m_i2c_release(struct inode *inode, struct file *file) {
    return 0;
}

static ssize_t m_i2c_read(struct file *m_file, char __user *buffer, size_t size,
     loff_t *offset) {
    
    uint8_t X_ACC_H = 0;
    uint8_t X_ACC_L = 0;
    uint8_t Y_ACC_H = 0;
    uint8_t Y_ACC_L = 0;
    uint8_t Z_ACC_H = 0;
    uint8_t Z_ACC_L = 0;
    uint8_t X_MAG_H = 0;
    uint8_t X_MAG_L = 0;
    uint8_t Y_MAG_H = 0;
    uint8_t Y_MAG_L = 0;
    uint8_t Z_MAG_H = 0;
    uint8_t Z_MAG_L = 0;    
    int16_t rcv[6] = {0};
    uint32_t status = 0;
    uint8_t writeBuffer[1];

    if(sizeof(rcv) > size)
        return -1;

    // >------------- Read accelerometer Axis -------------< //
    // Set the accel sensor address to be readed/written   
    iowrite32(LSM303_ACCELEROMETER_ADDR, i2c2_base + I2C_SA);   
    
    // Read all axis
    writeBuffer[0] = LSM303_REGISTER_ACCEL_OUT_X_H_A;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));  
    X_ACC_H = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_ACCEL_OUT_X_L_A;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    X_ACC_L = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_ACCEL_OUT_Y_H_A;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));  
    Y_ACC_H = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_ACCEL_OUT_Y_L_A;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    Y_ACC_L = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_ACCEL_OUT_Z_H_A;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));  
    Z_ACC_H = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_ACCEL_OUT_Z_L_A;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    Z_ACC_L = m_i2c_readByte();

    // >------------- Read accelerometer Axis -------------< //
    // Set the mag sensor address to be readed/written   
    iowrite32(LSM303_MAGNETIC_ADDR, i2c2_base + I2C_SA);   
    
    // Read all axis
    writeBuffer[0] = LSM303_REGISTER_MAG_OUT_X_H_M;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));  
    X_MAG_H = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_MAG_OUT_X_L_M;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    X_MAG_L = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_MAG_OUT_Y_H_M;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));  
    Y_MAG_H = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_MAG_OUT_Y_L_M;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    Y_MAG_L = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_MAG_OUT_Z_H_M;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));  
    Z_MAG_H = m_i2c_readByte();

    writeBuffer[0] = LSM303_REGISTER_MAG_OUT_Z_L_M;
    m_i2c_writeBuffer(writeBuffer, sizeof(writeBuffer));
    Z_MAG_L = m_i2c_readByte();

    // >----------------- Reassemble Data -----------------< //
    rcv[0] = (int16_t)((X_ACC_H << 8) | X_ACC_L) >> LSM303ACC_SHIFT;
    rcv[1] = (int16_t)((Y_ACC_H << 8) | Y_ACC_L) >> LSM303ACC_SHIFT;
    rcv[2] = (int16_t)((Z_ACC_H << 8) | Z_ACC_L) >> LSM303ACC_SHIFT;
    rcv[3] = (int16_t)((X_MAG_H << 8) | X_MAG_L);
    rcv[4] = (int16_t)((Y_MAG_H << 8) | Y_MAG_L);
    rcv[5] = (int16_t)((Z_MAG_H << 8) | Z_MAG_L);

    status = copy_to_user(buffer, (const void *) &rcv, sizeof(rcv));

    if(status != 0){
        print_error_msg_w_status(" I2C_READ  ", __FILE__, (char*)__FUNCTION__,
            __LINE__, status);

        return -1;
    }

    return sizeof(rcv);
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