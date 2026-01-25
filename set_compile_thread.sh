#!/bin/bash

# Function: set_compile_params
# Purpose: Dynamically determines optimal compilation parameters (MAX_JOBS and NVCC_THREADS)
#          based on available system CPU threads and RAM.
#          It exports the calculated MAX_JOBS and NVCC_THREADS as global environment variables.
set_compile_params() {
    echo "--- Calculating compilation parameters based on system resources ---"

    # Get number of CPU threads
    local NUM_THREADS=$(nproc)
    # Get available RAM in GB
    local RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    echo "  System resources detected:"
    echo "    CPU threads: $NUM_THREADS"
    echo "    RAM: ${RAM_GB}GB"

    # Calculate the maximum product (MAX_JOBS x NVCC_THREADS)
    # Constraints:
    # - MAX_JOBS x NVCC_THREADS(<= 4) <= NUM_THREADS (CPU thread constraint)
    # - 2.8GB x MAX_JOBS x NVCC_THREADS(<= 4) <= RAM_GB (RAM constraint, assuming ~2.8GB per compile job + sub-threads)

    # Calculate max product based on CPU threads
    local MAX_PRODUCT_CPU=$NUM_THREADS
    # Calculate max product based on RAM
    local MAX_PRODUCT_RAM=$(awk -v ram="$RAM_GB" 'BEGIN {print int(ram / 2.8)}')

    # The actual MAX_PRODUCT is the minimum of the two constraints
    local MAX_PRODUCT=$((MAX_PRODUCT_CPU < MAX_PRODUCT_RAM ? MAX_PRODUCT_CPU : MAX_PRODUCT_RAM))

    # Determine MAX_JOBS and NVCC_THREADS based on MAX_PRODUCT
    # Aim: MAX_JOBS x NVCC_THREADS ≈ MAX_PRODUCT, with NVCC_THREADS <= 4

    local BASE_THREADS=$(awk -v max="$MAX_PRODUCT" 'BEGIN {print int(sqrt(max))}')

    # Special handling for systems with low RAM (<= 16GB)
    if (( RAM_GB <= 16 )); then
        echo "  Detected RAM <= 16GB. Using conservative parameters."
        NVCC_THREADS=1
        MAX_JOBS=2
    elif (( BASE_THREADS <= 4 )); then
        # If sqrt(MAX_PRODUCT) is 4 or less, set both NVCC_THREADS and MAX_JOBS to this value
        NVCC_THREADS=$BASE_THREADS
        MAX_JOBS=$BASE_THREADS
    else
        # Otherwise, cap NVCC_THREADS at 4 and calculate MAX_JOBS accordingly
        NVCC_THREADS=4
        MAX_JOBS=$((MAX_PRODUCT / NVCC_THREADS))
    fi

    # Ensure minimum values of 1 for both parameters
    MAX_JOBS=$((MAX_JOBS < 1 ? 1 : MAX_JOBS))
    NVCC_THREADS=$((NVCC_THREADS < 1 ? 1 : NVCC_THREADS))

    # Export the calculated values as global environment variables
    export MAX_JOBS
    export NVCC_THREADS

    echo "  Calculated parameters:"
    echo "    MAX_JOBS: $MAX_JOBS"
    echo "    NVCC_THREADS: $NVCC_THREADS"
    echo "-----------------------------------"
}

# --- How to use this function ---

# 1. Save the above code to a file, e.g., `set_compile_env.sh`
# 2. In your main build script, `source` this file and then call the function.

# Example main build script `build.sh`:
# #!/bin/bash
# # Source the utility function
# source ./set_compile_env.sh

# # Call the function to set the compilation parameters
# set_compile_params
