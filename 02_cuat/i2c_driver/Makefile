
KERNEL_SOURCE := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)
INCLUDES := $(PWD)/inc

MOD_NAME = i2c_driver
MOD_PATH = src/${MOD_NAME}

DEV_NAME = i2c_TM
DEV_PATH = /dev/${DEV_NAME}

# Converts a module object in LKM
obj-m += $(MOD_PATH).o

## Test app ##
# C compiler
CC = gcc

# Linker flags
LFLAGS = -lm

# Source Path
TEST1_SRC = test/test1.c
TEST2_SRC = test/test2.c
CAL_SRC = test/mag_calibration.c

# Output
TEST_BUILD_PATH = test/build
TEST1_OUT = ${TEST_BUILD_PATH}/test1
TEST2_OUT = ${TEST_BUILD_PATH}/test2
CAL_OUT = ${TEST_BUILD_PATH}/calibration

#______________________________________________________________________________#
#                                 Rules                                        #
#______________________________________________________________________________#

all: Compile_module test1_app test2_app calibration_app
	
clean: rm_mod
	@echo " "
	@echo "====> Cleaning Project <===="
	@echo " "
	@rm -fr ${TEST_BUILD_PATH}
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} -I${INCLUDES} clean
	@echo " "
	@echo "====> Cleaned! <===="
	@echo " "

rm_mod:
	@sudo rmmod ${MOD_NAME} || true
	@echo " "
	@echo "====> Device \"${DEV_NAME}\" successfully removed! <===="
	@echo " "

test1_app:
	@mkdir -p ${TEST_BUILD_PATH}
	@echo " "
	@echo "====> Compiling test1 app at \"test/\" <===="
	@${CC} ${TEST1_SRC} -o ${TEST1_OUT} ${LFLAGS}
	@echo "====> Done! <===="
	@echo " "

test2_app:
	@mkdir -p ${TEST_BUILD_PATH}
	@echo " "
	@echo "====> Compiling test2 app at \"test/\" <===="
	@${CC} ${TEST2_SRC} -o ${TEST2_OUT} ${LFLAGS}
	@echo "====> Done! <===="
	@echo " "

calibration_app:
	@mkdir -p ${TEST_BUILD_PATH}
	@echo " "
	@echo "====> Compiling calibration app at \"test/\" <===="
	@${CC} ${CAL_SRC} -o ${CAL_OUT} ${LFLAGS}
	@echo "====> Done! <===="
	@echo " "

Compile_module:
	@sudo rmmod ${MOD_NAME} || true
	@echo " "
	@echo "====> Compiling module \"${MOD_NAME}\" <===="
	@echo " "
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} -I${INCLUDES} modules
	@echo " "
	@echo "====> Installing module \"${MOD_NAME}\" <===="
	@sudo insmod ${MOD_PATH}.ko
	@sudo chmod 777 ${DEV_PATH}
	@echo "====> Device successfully installed as \"${DEV_NAME}\"! <===="
	@echo " "
