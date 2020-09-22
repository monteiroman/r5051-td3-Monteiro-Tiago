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

#define CLASS_NAME      "i2c_class"
#define BASE_MINOR      0
#define MINOR_COUNT     1
#define DEVICE_NAME     "i2c_TM"
#define NAME_SHORT      "i2c_TM"
#define DEVICE_PARENT   NULL
#define DEVICE_DATA     NULL


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

