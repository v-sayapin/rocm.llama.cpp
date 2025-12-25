#!/bin/bash
set -euo pipefail

IMAGE="${IMAGE:-rocm.llama.cpp}"

PORT="${PORT:-8080}"

MODELS_DIR="${MODELS_DIR:-./models}"
CONFIG_DIR="${CONFIG_DIR:-./config}"

docker run -it --rm \
  --name=llama-server \
  --device=/dev/kfd \
  --device=/dev/dri \
  --group-add video \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  --ipc=host \
  --shm-size 16G \
  -p "127.0.0.1:${PORT}:8080" \
  -v "${MODELS_DIR}:/models:ro" \
  -v "${CONFIG_DIR}:/config:ro" \
  "${IMAGE}" \
    --models-dir /models \
    --models-preset /config/presets.ini \
    "$@"
