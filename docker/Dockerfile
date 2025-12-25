# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=24.04
ARG ROCM_VERSION=7.1.1
ARG LLAMA_CPP_TAG=b7636
ARG GPU_TARGETS=gfx1100

ARG USER=llama
ARG UID=1001
ARG GID=1001

ARG ROCM_IMAGE=rocm/dev-ubuntu-${UBUNTU_VERSION}:${ROCM_VERSION}
ARG ROCM_BUILD_IMAGE=${ROCM_IMAGE}-complete
ARG ROCM_RUNTIME_IMAGE=${ROCM_IMAGE}



FROM ${ROCM_BUILD_IMAGE} AS build

ARG LLAMA_CPP_TAG
ARG GPU_TARGETS

ENV AMDGPU_TARGETS=${GPU_TARGETS}
ENV PATH="/opt/rocm/llvm/bin:/opt/rocm/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    libcurl4-openssl-dev \
    libgomp1 \
    ninja-build \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN curl -Lo /tmp/llama.cpp.tar.gz \
    "https://codeload.github.com/ggml-org/llama.cpp/tar.gz/refs/tags/${LLAMA_CPP_TAG}" \
  && tar -xzf /tmp/llama.cpp.tar.gz --strip-components=1 \
  && rm -f /tmp/llama.cpp.tar.gz

RUN HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
  cmake -S . -B build -G Ninja \
    -DGGML_HIP=ON \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DGPU_TARGETS="${GPU_TARGETS}" \
    -DGGML_NATIVE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_TESTS=OFF \
  && cmake --build build --config Release -t llama-server -j "$(nproc)"

RUN mkdir -p /dist/bin /dist/lib \
  && cp build/bin/llama-server /dist/bin \
  && llvm-strip -s /dist/bin/llama-server \
  && find build/bin -name "*.so*" -exec cp -a {} /dist/lib \;



FROM ${ROCM_RUNTIME_IMAGE} AS runtime

ARG USER
ARG UID
ARG GID

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    hipblas \
    libgomp1 \
    rocwmma \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g ${GID} ${USER} \
  && useradd -u ${UID} -g ${USER} -m -s /bin/bash ${USER}

COPY --from=build /dist /app

RUN echo "/app/lib" > /etc/ld.so.conf.d/llama.cpp.conf \
  && ldconfig

ENV PATH="/app/bin:${PATH}"
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080

EXPOSE 8080

HEALTHCHECK --start-period=60s \
  CMD sh -c 'curl -f http://127.0.0.1:${LLAMA_ARG_PORT}/health || exit 1'

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["llama-server"]
