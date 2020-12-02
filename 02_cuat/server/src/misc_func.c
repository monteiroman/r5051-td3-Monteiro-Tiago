#include "../inc/misc_func.h"

void print_error (char* e_file, char* e_msg)
{
    char err[255] = "[ERROR] ";
    strcat(err, e_file);
    strcat(err, " | ");
    strcat(err, e_msg);
    
    perror(err);
}

void print_msg (char* m_file, char* m_msg)
{
    char msg[255] = "[LOG]   ";
    strcat(msg, m_file);
    strcat(msg, " | ");
    strcat(msg, m_msg);
    
    printf("%s\n", msg);
}

void print_msg_wValue (char* m_file, char* m_msg, long val)
{
    char msg[255] = "[LOG]   ", buf[255];
    strcat(msg, m_file);
    strcat(msg, " | ");
    snprintf(buf, 255, m_msg, val);
    strcat(msg, buf);

    printf("%s\n", msg);
}

void print_msg_wFloatValue (char* m_file, char* m_msg, float val)
{
    char msg[255] = "[LOG]   ", buf[255];
    strcat(msg, m_file);
    strcat(msg, " | ");
    snprintf(buf, 255, m_msg, val);
    strcat(msg, buf);

    printf("%s\n", msg);
}