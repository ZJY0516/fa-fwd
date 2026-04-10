#!/bin/bash
set -e

echo "=== Building fa3_fwd wheel for aarch64 ==="
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
NEWNAME=$(basename "$WHL" | sed 's/linux_aarch64/manylinux_2_24_aarch64/')
cp "$WHL" "/output/$NEWNAME"

echo "=== Final wheel ==="
ls -la /output/$NEWNAME
