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

#define CLASS        "i2c_class"
#define MINORBASE    0
#define MINORCOUNT   1
#define NAME         "td3_i2c"
#define NAME_SHORT   "td3_i2c"


// Function definitions from i2c_driver.c ______________________________________
static int __init i2c_init(void);

static void __exit i2c_exit(void);


// Function definitions from i2c_misc_func.c ___________________________________
void print_error_msg_w_status(char* e_action, char* e_file, char* e_func,
    int e_line, int e_status);

void print_error_msg_wo_status(char* e_action, char* e_file, char* e_func,
    int e_line, int e_status);

void print_info_msg(char* i_action, char* i_file, char* i_msg);



struct state {
  struct class *m_i2c_class;
  struct device *m_i2c_device;
  struct cdev m_i2c_cdev;
  dev_t m_i2c_device_type;

  unsigned int freq;
  void __iomem *base;
  int irq;
};