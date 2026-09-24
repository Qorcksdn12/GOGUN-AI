#!/bin/sh
# Builds the C simulator twice (both are bit-identical to sim.js: -ffp-contract=off keeps IEEE semantics):
#   libsim.so      single thread  (train.py, eval scripts)
#   libsim_omp.so  OpenMP threads (train_gpu.py uses every CPU core for the environments)
set -e
cd "$(dirname "$0")"
gcc -O3 -ffp-contract=off -shared -fPIC -o libsim.so sim.c -lm
echo "libsim.so built"
if gcc -O3 -ffp-contract=off -fopenmp -shared -fPIC -o libsim_omp.so sim.c -lm 2>/dev/null; then echo "libsim_omp.so built (OpenMP)"; else echo "OpenMP not available: train_gpu.py will use the single thread libsim.so"; fi
