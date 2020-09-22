/*____________________________________________________________________________*/
/*    File operations for the i2c driver.                                     */
/*        Functions:                                                          */
/*              m_i2c_open                                                    */
/*              m_i2c_close                                                   */
/*              m_i2c_read                                                    */
/*              m_i2c_write                                                   */
/*____________________________________________________________________________*/

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
