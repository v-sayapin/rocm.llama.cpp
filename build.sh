#!/bin/bash

readonly UBUNTU_VERSION=24.04
readonly ROCM_VERSION=7.1.1
readonly LLAMA_CPP_REF=b7540
readonly AMDGPU_TARGETS=gfx1100

docker buildx build \
  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
  --build-arg ROCM_VERSION=${ROCM_VERSION} \
  --build-arg LLAMA_CPP_REF=${LLAMA_CPP_REF} \
  --build-arg AMDGPU_TARGETS=${AMDGPU_TARGETS} \
  --platform=linux/amd64 \
  -t rocm.llama.cpp \
  -f ./docker/Dockerfile . \
  --load
