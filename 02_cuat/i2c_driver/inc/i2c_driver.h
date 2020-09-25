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


/*____________________________________________________________________________*/
/*                                                                            */
/*                              Definitions                                   */
/*                                                                            */
/*____________________________________________________________________________*/

/* Module ____________________________________*/
#define CLASS_NAME                  "i2c_class"
#define BASE_MINOR                  0
#define MINOR_COUNT                 1
#define DEVICE_NAME                 "i2c_TM"
#define NAME_SHORT                  "i2c_TM"
#define DEVICE_PARENT               NULL
#define DEVICE_DATA                 NULL

/* BBB _______________________________________*/
// Pagina 4601 fundamental
#define CM_PER                      0x44E00000
#define CM_PER_LEN                  0x0400
#define CM_PER_I2C2_CLKCTRL_OFFSET  0x0044
#define CONTROL_MODULE              0x44E10000
#define CONTROL_MODULE_LEN          0x2000

#define CONF_UART1_RTSN_OFFSET      0x097C
#define CONF_UART1_CTSN_OFFSET      0x0978

#define I2C_IRQSTATUS               0x28
#define I2C_IRQSTATUS_XRDY          0x10
#define I2C_IRQENABLE_SET           0x2C
#define I2C_IRQSTATUS_RAW           0x24
#define I2C_IRQENABLE_CLR           0x30

#define I2C_SCLL                    0xB4     
#define I2C_SCLH                    0xB8 
#define I2C_OA                      0xA8     
#define I2C_SA                      0xAC
#define I2C_PSC                     0xB0     
#define I2C_CON                     0xA4     

/*____________________________________________________________________________*/
/*                                                                            */
/*                               Variables                                    */
/*                                                                            */
/*____________________________________________________________________________*/

int virt_irq;
static void __iomem *i2c2_base, *cmPer_base, *controlModule_base;


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

