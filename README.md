# Flash-Attention-3 Forward-Only Kernel

This repository bundles the Flash-Attention-3 forward-only kernel and the tooling required to build a lightweight Python wheel. It is intended for inference scenarios where backward operators and optional features are unnecessary.

## Highlights
- Ships only the Flash-Attention-3 forward path while disabling backward kernels, local attention, paged KV cache, FP16 kernels, and other extras to minimize the wheel size.
- Applies a patch that renames the public interface to `fa3_fwd_interface`, making the forward kernel easy to import from Python.

## Prerequisites(same as upstream)
- **Python**: 3.9 or later
- **PyTorch**: 2.9.0
- **Build dependencies**: `ninja`, `packaging`, `wheel`

## Quick Start
1. Clone the repository and initialize submodules:
	```bash
	git clone --recursive <repo-url>
	cd fa3-fwd
	# If --recursive was omitted during clone, run:
	git submodule update --init --recursive
	```
2. Create a Python virtual environment and install dependencies:
	```bash
	uv venv --python 3.12 --seed
	source .venv/bin/activate
	uv pip install -r requirements.txt
	```
3. Build the forward-only wheel:
	```bash
	bash build_fa3.sh
	```
	The script:
	- Sources [set_compile_env.sh](set_compile_env.sh) to compute `MAX_JOBS` and `NVCC_THREADS`
	- Applies the custom patch and interface rename inside the Flash-Attention submodule
	- Runs `python setup.py bdist_wheel` under [flash-attention/hopper](flash-attention/hopper)

4. Install the generated wheel (example):
	```bash
	pip install flash-attention/hopper/dist/fa3_fwd-0.0.1-cp*-linux_x86_64.whl
	```

## Python Usage Example
```python
import torch
from fa3_fwd_interface import flash_attn_func

# Inputs must already live on CUDA and satisfy Flash-Attention-3 constraints
out = flash_attn_func(q, k, v, causal=True)
```

> This package exposes only the forward kernel. For backward support or additional features, depend on the upstream Flash-Attention project instead.


## Troubleshooting
- **Out-of-memory during compilation**: The build script already throttles concurrency, but you can enforce `MAX_JOBS=1 NVCC_THREADS=1` before running `bash build_fa3.sh`.
- **CUDA mismatch errors**: Confirm that `nvcc --version` aligns with `torch.version.cuda`.

## Repository Layout
- [build_fa3.sh](build_fa3.sh): Main build entry point
- [set_compile_env.sh](set_compile_env.sh): Resource-based compiler configuration helper
- [hopper_setup_py.patch](hopper_setup_py.patch): Patch applied to the upstream `setup.py`
- [flash-attention](flash-attention): Upstream Flash-Attention submodule

Customize further by editing environment variables in the build script or modifying the submodule before the patch is applied (for example to re-enable additional datatypes or kernels).
