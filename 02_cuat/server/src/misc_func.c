#include "../inc/misc_func.h"

void print_error (char* e_file, char* e_msg)
{
    char err[] = "[ERROR] ";
    strcat(err, e_file);
    strcat(err, " | ");
    strcat(err, e_msg);
    
    perror(err);
}