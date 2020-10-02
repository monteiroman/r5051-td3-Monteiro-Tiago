#include <linux/init.h>
#include <linux/module.h>
#include <linux/device.h>
#include <linux/types.h>
#include <linux/jiffies.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/interrupt.h>
#include <linux/pm_runtime.h>
#include <linux/delay.h>
#include <linux/slab.h>
#include <linux/of_platform.h>
#include <linux/of_irq.h>
#include <linux/of_address.h>
#include <linux/uaccess.h>
#include <linux/pinctrl/consumer.h>
#include <linux/wait.h>


/*____________________________________________________________________________*/
/*                                                                            */
/*                              Definitions                                   */
/*                                                                            */
/*____________________________________________________________________________*/

/* Module ____________________________________*/
#define CLASS_NAME                              "i2c_class"
#define BASE_MINOR                              0
#define MINOR_COUNT                             1
#define DEVICE_NAME                             "i2c_TM"
#define NAME_SHORT                              "i2c_TM"
#define DEVICE_PARENT                           NULL
#define DEVICE_DATA                             NULL

/* BBB _______________________________________*/
// I2C Registers in page 4601
#define CM_PER                                  0x44E00000
#define CM_PER_LEN                              0x0400
#define CM_PER_I2C2_CLKCTRL_OFFSET              0x0044

#define CONTROL_MODULE                          0x44E10000
#define CONTROL_MODULE_LEN                      0x2000

#define CONF_UART1_RTSN_OFFSET                  0x097C
#define CONF_UART1_CTSN_OFFSET                  0x0978

#define I2C_IRQSTATUS_RAW                       0x24            // Page 4606
#define I2C_IRQSTATUS                           0x28            // Page 4612
#define I2C_IRQSTATUS_XRDY                      0x10            // Page 4613
#define I2C_IRQSTATUS_RRDY                      0x08            // Page 4613
#define I2C_IRQENABLE_SET                       0x2C            // Page 4614
#define I2C_IRQENABLE_CLR                       0x30            // Page 4616
#define I2C_CNT                                 0x98            // Page 4632
#define I2C_DATA                                0x9C            // Page 4633
#define I2C_CON                                 0xA4            // Page 4634 
#define I2C_CON_START                           0x01            // Page 4636
#define I2C_CON_STOP                            0x02            // Page 4636
#define I2C_OA                                  0xA8            // Page 4637
#define I2C_SA                                  0xAC            // Page 4638
#define I2C_PSC                                 0xB0            // Page 4639
#define I2C_SCLL                                0xB4            // Page 4640
#define I2C_SCLH                                0xB8            // Page 4641

/* LSM303 ____________________________________*/
#define LSM303_ACCELEROMETER_ADDR               0x19
#define LSM303_MAGNETIC_ADDR                    0x1E

#define LSM303_REGISTER_ACCEL_CTRL_REG1_A       0x20
#define LSM303_REGISTER_ACCEL_CTRL_REG3_A       0x22
#define LSM303_REGISTER_ACCEL_CTRL_REG4_A       0x23
#define LSM303_REGISTER_ACCEL_CTRL_REG2_A       0x21
#define LSM303_REGISTER_ACCEL_CTRL_REG5_A       0x24
#define LSM303_REGISTER_ACCEL_CTRL_REG6_A       0x25
#define LSM303_REGISTER_ACCEL_REFERENCE_A       0x26   
#define LSM303_REGISTER_ACCEL_STATUS_REG_A      0x27   
#define LSM303_REGISTER_ACCEL_OUT_X_L_A         0x28
#define LSM303_REGISTER_ACCEL_OUT_X_H_A         0x29
#define LSM303_REGISTER_ACCEL_OUT_Y_L_A         0x2A
#define LSM303_REGISTER_ACCEL_OUT_Y_H_A         0x2B
#define LSM303_REGISTER_ACCEL_OUT_Z_L_A         0x2C
#define LSM303_REGISTER_ACCEL_OUT_Z_H_A         0x2D
#define LSM303_REGISTER_ACCEL_FIFO_CTRL_REG_A   0x2E
#define LSM303_REGISTER_ACCEL_FIFO_SRC_REG_A    0x2F
#define LSM303_REGISTER_ACCEL_INT1_CFG_A        0x30
#define LSM303_REGISTER_ACCEL_INT1_SOURCE_A     0x31
#define LSM303_REGISTER_ACCEL_INT1_THS_A        0x32
#define LSM303_REGISTER_ACCEL_INT1_DURATION_A   0x33
#define LSM303_REGISTER_ACCEL_INT2_CFG_A        0x34
#define LSM303_REGISTER_ACCEL_INT2_SOURCE_A     0x35
#define LSM303_REGISTER_ACCEL_INT2_THS_A        0x36
#define LSM303_REGISTER_ACCEL_INT2_DURATION_A   0x37
#define LSM303_REGISTER_ACCEL_CLICK_CFG_A       0x38
#define LSM303_REGISTER_ACCEL_CLICK_SRC_A       0x39
#define LSM303_REGISTER_ACCEL_CLICK_THS_A       0x3A
#define LSM303_REGISTER_ACCEL_TIME_LIMIT_A      0x3B
#define LSM303_REGISTER_ACCEL_TIME_LATENCY_A    0x3C
#define LSM303_REGISTER_ACCEL_TIME_WINDOW_A     0x3D

#define LSM303_REGISTER_MAG_CRA_REG_M           0x00
#define LSM303_REGISTER_MAG_CRB_REG_M           0x01
#define LSM303_REGISTER_MAG_MR_REG_M            0x02
#define LSM303_REGISTER_MAG_OUT_X_H_M           0x03
#define LSM303_REGISTER_MAG_OUT_X_L_M           0x04
#define LSM303_REGISTER_MAG_OUT_Z_H_M           0x05
#define LSM303_REGISTER_MAG_OUT_Z_L_M           0x06
#define LSM303_REGISTER_MAG_OUT_Y_H_M           0x07
#define LSM303_REGISTER_MAG_OUT_Y_L_M           0x08
#define LSM303_REGISTER_MAG_SR_REG_Mg           0x09
#define LSM303_REGISTER_MAG_IRA_REG_M           0x0A
#define LSM303_REGISTER_MAG_IRB_REG_M           0x0B
#define LSM303_REGISTER_MAG_IRC_REG_M           0x0C
#define LSM303_REGISTER_MAG_TEMP_OUT_H_M        0x31
#define LSM303_REGISTER_MAG_TEMP_OUT_L_M        0x32


/*____________________________________________________________________________*/
/*                                                                            */
/*                               Variables                                    */
/*                                                                            */
/*____________________________________________________________________________*/

int virt_irq;
int i2c_txData_size = 0;
int i2c_txData_byteCount = 0;
static void __iomem *i2c2_base, *cmPer_base, *controlModule_base;
uint8_t *i2c_txData;// = 0;
uint8_t i2c_rxData = 0;

// queue
volatile int m_i2c_wk_condition = 0;
wait_queue_head_t m_i2c_wk = __WAIT_QUEUE_HEAD_INITIALIZER(m_i2c_wk);


/*____________________________________________________________________________*/
/*                                                                            */
/*                              Structures                                    */
/*                                                                            */
/*____________________________________________________________________________*/

static struct {
  struct class *m_i2c_class;
  struct device *m_i2c_device;
  struct cdev m_i2c_cdev;
  dev_t m_i2c_device_type;

  unsigned int freq;
  void __iomem *base;
  int irq;
} state;

struct file_operations mFileOps;
