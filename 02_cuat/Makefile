DRIVER_PATH = i2c_driver
SERVER_PATH = server

all: build_server build_driver

clean: clean_server clean_driver 
	
rm_mod:
	@cd ${DRIVER_PATH} && ${MAKE} rm_mod

build_server:
	@cd ${SERVER_PATH} && ${MAKE}

build_driver:
	@cd ${DRIVER_PATH} && ${MAKE}

clean_server:
	@cd ${SERVER_PATH} && ${MAKE} clean

clean_driver:
	@cd ${DRIVER_PATH} && ${MAKE} clean

run_server:
	./server/build/web_server 11111

run_test2:
	./i2c_driver/test/build/test2