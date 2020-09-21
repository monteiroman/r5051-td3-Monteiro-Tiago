#include "../inc/i2c_driver.h"


// Error message with status.
void print_error_msg_w_status(char* e_action, char* e_file, char* e_func,
    int e_line, int e_status){

    printk(KERN_ERR "[E]: %s | File: %s | Msg:", e_action, e_file);
    printk(KERN_ERR " ERROR in function: %s, line: %d status: %d)\n", 
            e_func, e_line, status);
}

// Error message without status.
void print_error_msg_wo_status(char* e_action, char* e_file, char* e_func,
    int e_line){
    
    printk(KERN_ERR "[E]: %s | File: %s | Msg:", e_action, e_file);
    printk(KERN_ERR " ERROR in function: %s, line: %d\n", e_func, e_line);
}

// Information message.
void print_info_msg(char* i_action, char* i_file, char* i_msg){

    printk(KERN_INFO "[I]: %s | File: %s | Msg: %s\n", i_action, i_file, i_msg);
}