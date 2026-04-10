# FlashAttention3 Forward Build Dockerfile
# Multi-arch support via Docker BuildKit --platform
#
# Build examples:
#   # ARM64 (native or cross-compile)
#   docker buildx build --platform linux/arm64 -t fa3-fwd:cu128-arm64 --load .
#
#   # x86_64
#   docker buildx build --platform linux/amd64 -t fa3-fwd:cu128-x86 --load .
#
#   # Multi-arch build and push
#   docker buildx build --platform linux/amd64,linux/arm64 -t yourrepo/fa3-fwd:latest --push .

# CUDA configuration
ARG CUDA_VERSION=12.8
ARG PYTHON_VERSION=3.10

# BuildKit automatically selects architecture based on --platform
# TARGETARCH = amd64 or arm64
FROM --platform=$TARGETPLATFORM quay.io/pypa/manylinux_2_28_${TARGETARCH}

# Re-declare ARGs (required after FROM)
ARG CUDA_VERSION
ARG PYTHON_VERSION

# Map Docker's TARGETARCH to CUDA repo architecture naming
# amd64 -> x86_64, arm64 -> sbsa
RUN case "${TARGETARCH}" in \
        amd64)  CUDA_ARCH="x86_64" ;; \
        arm64)  CUDA_ARCH="sbsa" ;; \
        *)      echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    CUDA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/rhel8/${CUDA_ARCH}/cuda-rhel8.repo" && \
    echo "Installing CUDA for architecture: ${CUDA_ARCH}" && \
    dnf install -y epel-release && \
    dnf config-manager --add-repo ${CUDA_REPO_URL} && \
    CUDA_PKG_SUFFIX=$(echo ${CUDA_VERSION} | tr '.' '-') && \
    dnf install -y cuda-toolkit-${CUDA_PKG_SUFFIX} && \
    dnf clean all

ENV PATH="/usr/local/cuda-${CUDA_VERSION}/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-${CUDA_VERSION}/lib64:${LD_LIBRARY_PATH}"
ENV CUDA_HOME="/usr/local/cuda-${CUDA_VERSION}"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Create Python venv with uv
RUN uv venv /opt/venv --python ${PYTHON_VERSION}
ENV PATH="/opt/venv/bin:${PATH}"
ENV VIRTUAL_ENV="/opt/venv"

# Fix git safe.directory for mounted volumes
RUN git config --global --add safe.directory '*'

WORKDIR /build/fa-fwd
COPY requirements.txt .

# Install dependencies from requirements.txt with auto-derived PyTorch index
# Derives extra-index-url from CUDA_VERSION (e.g., 12.8 -> cu128, 13.0 -> cu130)
RUN CUDA_MAJOR=$(echo ${CUDA_VERSION} | cut -d. -f1) && \
    CUDA_MINOR=$(echo ${CUDA_VERSION} | cut -d. -f2) && \
    PYTORCH_INDEX="cu${CUDA_MAJOR}${CUDA_MINOR}" && \
    echo "Using PyTorch extra-index-url: https://download.pytorch.org/whl/${PYTORCH_INDEX}" && \
    uv pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/${PYTORCH_INDEX} && \
    uv pip install setuptools
