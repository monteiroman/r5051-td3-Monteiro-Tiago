#include "../inc/file_functions.h"

extern struct configValues *configValues_data, cfgVal;
extern sem_t *cfg_semaphore;

off_t fsize(const char * path) {
	struct stat st;

	if (stat(path, &st) == 0) {
		return S_ISDIR(st.st_mode) ? 0 : st.st_size;
	}
	return -1;
}

unsigned char* readFile(const char* path, size_t* size){
    // Get file size.
    size_t _size = fsize(path);
    if(_size < 1){
        return NULL;
    }

    // Open file.
    FILE* fp = fopen(path, "r");
    if(fp == NULL){
        return NULL;
    }

    // Alloc memory.
    unsigned char* buffer = calloc(_size, sizeof(unsigned char));

    // Read file.
    if(fread(buffer, sizeof(unsigned char), _size, fp) < 0){
        return NULL;
    } 
    fclose(fp);

    *size = _size;
    return buffer;
}

void cfgRead(){
    size_t size = 0;
    int state = 0;
    int bufIdx = 0;
    unsigned char buffer[1024] = {0};

    // Read file.
    unsigned char* cfgBuffer = readFile(CONFIG_FILE, &size);
    if(cfgBuffer == NULL){
        return;
    }

    // Search values.
    for(int i=0; i<size; i++){
        unsigned char c = cfgBuffer[i];
        switch(c){
            case 'b':
            case 'c':
            case 'm':
            case 's':
            case 'x':
            case 'y':
            case 'f':
                state = c;
                bufIdx = 0;
                bzero(buffer, 1024);
                break;
            case '=':
                break;
            case '\n':
                switch(state){
                    case 'b':
                        cfgVal.backlog = atoi(buffer);
                        break;
                    case 'c':
                        cfgVal.current_connections = atoi(buffer);
                        break;
                    case 'm':
                        cfgVal.max_connections = atoi(buffer);
                        break;
                    case 's':
                        cfgVal.mean_samples = atoi(buffer);
                        break;
                    case 'x':
                        cfgVal.X_HardOffset = atoi(buffer);
                        break;
                    case 'y':
                        cfgVal.Y_HardOffset = atoi(buffer);
                        break;
                    case 'f':
                        cfgVal.sensor_freq = atof(buffer);
                        break;
                }
                break;
            default:
                buffer[bufIdx] = c;
                bufIdx++;
                break;
        }
    }
    // Copy values to shared mem.
    sem_wait(cfg_semaphore);
    memcpy(configValues_data, &cfgVal, sizeof(struct configValues));
    sem_post(cfg_semaphore);
}