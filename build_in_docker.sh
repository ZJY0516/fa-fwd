#!/bin/bash
set -e

# Auto-detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64)
        PLATFORM_TAG="aarch64"
        ;;
    x86_64)
        PLATFORM_TAG="x86_64"
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        exit 1
        ;;
esac

echo "=== Building fa3_fwd wheel for ${PLATFORM_TAG} ==="
echo "CUDA: $(nvcc --version | tail -1)"
echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__, "cuda:", torch.version.cuda)')"

cd /build/fa-fwd
bash build_fa3.sh

echo "=== Raw wheel ==="
ls -la build/*.whl

# Check wheel platform compatibility
auditwheel show build/*.whl

# Rename platform tag to manylinux_2_24
WHL=$(ls build/*.whl)
NEWNAME=$(basename "$WHL" | sed "s/linux_${PLATFORM_TAG}/manylinux_2_24_${PLATFORM_TAG}/")
cp "$WHL" "/output/$NEWNAME"

echo "=== Final wheel ==="
ls -la /output/$NEWNAME
