# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=24.04
ARG ROCM_VERSION=7.1.1
ARG LLAMA_CPP_REF=b7540
ARG AMDGPU_TARGETS=gfx1100

ARG ROCM_IMAGE=rocm/dev-ubuntu-${UBUNTU_VERSION}:${ROCM_VERSION}
ARG ROCM_BUILD_IMAGE=${ROCM_IMAGE}-complete
ARG ROCM_RUNTIME_IMAGE=${ROCM_IMAGE}



FROM ${ROCM_BUILD_IMAGE} AS build

ARG LLAMA_CPP_REF
ARG AMDGPU_TARGETS
ENV AMDGPU_TARGETS=${AMDGPU_TARGETS}
ENV PATH="/opt/rocm/llvm/bin:/opt/rocm/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libcurl4-openssl-dev \
    ninja-build \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --filter=blob:none --no-checkout https://github.com/ggml-org/llama.cpp.git \
  && cd llama.cpp \
  && git fetch --depth 1 origin "${LLAMA_CPP_REF}" \
  && git checkout --detach FETCH_HEAD

WORKDIR /src/llama.cpp
RUN HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
  cmake -S . -B build -G Ninja \
    -DGGML_HIP=ON \
    -DAMDGPU_TARGETS="${AMDGPU_TARGETS}" \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DGGML_NATIVE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_TESTS=OFF \
  && cmake --build build --config Release -t llama-server -j "$(nproc)" \
  && llvm-strip -s build/bin/llama-server \
  && mkdir -p /dist/bin /dist/lib \
  && cp -a build/bin/llama-server /dist/bin \
  && find build/bin -name "*.so*" -exec cp -a {} /dist/lib \;



FROM ${ROCM_RUNTIME_IMAGE} AS runtime

ARG USER=llama
ARG UID=1001
ARG GID=1001

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    hipblas \
    libcurl4 \
    libgomp1 \
    rocwmma \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g ${GID} ${USER} \
  && useradd -u ${UID} -g ${USER} -m -s /bin/bash ${USER}

COPY --from=build /dist /app
RUN echo "/app/lib" > /etc/ld.so.conf.d/llama.cpp.conf \
  && ldconfig

USER ${USER}

ENV LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=8080

HEALTHCHECK --start-period=60s \
  CMD curl -f http://127.0.0.1:${LLAMA_ARG_PORT}/health || exit 1

ENTRYPOINT ["/app/bin/llama-server"]
EXPOSE 8080
