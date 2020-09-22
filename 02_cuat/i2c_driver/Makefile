

KERNEL_SOURCE := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)
INCLUDES := $(PWD)/inc

MOD_NAME = src/i2c_driver


obj-m += $(MOD_NAME).o


all:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} -I${INCLUDES} modules

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} -I${INCLUDES} clean

