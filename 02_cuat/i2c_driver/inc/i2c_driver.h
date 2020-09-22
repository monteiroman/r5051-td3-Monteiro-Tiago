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

#define CLASS_NAME      "i2c_class"
#define BASE_MINOR      0
#define MINOR_COUNT     1
#define DEVICE_NAME     "i2c_TM"
#define NAME_SHORT      "i2c_TM"
#define DEVICE_PARENT   NULL
#define DEVICE_DATA     NULL


// Function definitions from i2c_driver.c ______________________________________
static int __init i2c_init(void);

static void __exit i2c_exit(void);


// Function definitions from i2c_misc_func.c ___________________________________
void print_error_msg_w_status(char* e_action, char* e_file, char* e_func,
    int e_line, int e_status);

void print_error_msg_wo_status(char* e_action, char* e_file, char* e_func,
    int e_line);

void print_info_msg(char* i_action, char* i_file, char* i_msg);


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

irqreturn_t driver_isr(int irq, void *devid);
static int m_i2c_probe(struct platform_device *pdev);
static int m_i2c_remove(struct platform_device *pdev);
