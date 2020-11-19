# C compiler
CC = gcc

# Source
SRC_NAME = web_server.c
SRC_PATH = src/${SRC_NAME}

# Output
SERV_BUILD_PATH = build
OUT_NAME = web_server
OUT_PATH = ${SERV_BUILD_PATH}/${OUT_NAME}

all: build_server
	
clean:
	@echo " "
	@echo "====> Cleaning Server Project <===="
	@echo " "
	@rm -fr ${SERV_BUILD_PATH}
	@echo "====> Done! <===="
	@echo " "

build_server:
	@echo " "
	@echo "====> Building Server <===="
	@mkdir -p ${SERV_BUILD_PATH}
	@${CC} ${SRC_PATH} -o ${OUT_PATH}
	@echo "====> Done! <===="
	@echo " "

