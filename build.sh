#!/bin/bash

IMAGE="${IMAGE:-rocm.llama.cpp}"

UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
ROCM_VERSION="${ROCM_VERSION:-7.1.1}"
LLAMA_CPP_TAG="${LLAMA_CPP_TAG:-b7636}"
GPU_TARGETS="${GPU_TARGETS:-gfx1100}"

PLATFORM="${PLATFORM:-linux/amd64}"

docker buildx build \
  -f ./docker/Dockerfile . \
  --build-arg UBUNTU_VERSION="${UBUNTU_VERSION}" \
  --build-arg ROCM_VERSION="${ROCM_VERSION}" \
  --build-arg LLAMA_CPP_TAG="${LLAMA_CPP_TAG}" \
  --build-arg GPU_TARGETS="${GPU_TARGETS}" \
  --platform="${PLATFORM}" \
  -t "${IMAGE}" \
  --load
