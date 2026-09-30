// Source: lectures/Chapter 02 - Heterogeneous Data Parallel Computing.pdf
// PDF page(s): 18 (1-based).
// Complete kernel as shown; has no boundary check.

__global__ void vecadd_kernel(float* x, float* y, float* z, int N) {
    int i = blockDim.x*blockIdx.x + threadIdx.x;
    z[i] = x[i] + y[i];
}
