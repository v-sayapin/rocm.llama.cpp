#!/bin/bash

readonly CONTAINER_NAME="llama-server"

readonly HOST_MODELS_DIR="./models"
readonly HOST_CONFIG_DIR="./config"

readonly MODELS_DIR="/models"
readonly CONFIG_DIR="/config"
readonly PRESETS_PATH="${CONFIG_DIR}/presets.ini"

docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

docker run -it \
  --name=${CONTAINER_NAME} \
  --device=/dev/kfd --device=/dev/dri \
  --group-add video --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  --ipc=host --shm-size 16G \
  -p 127.0.0.1:8080:8080 \
  -v ${HOST_MODELS_DIR}:${MODELS_DIR}:ro \
  -v ${HOST_CONFIG_DIR}:${CONFIG_DIR}:ro \
  rocm.llama.cpp \
    --models-dir ${MODELS_DIR} \
    --models-preset ${PRESETS_PATH}
