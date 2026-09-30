// Source: lectures/Chapter 02 - Heterogeneous Data Parallel Computing.pdf
// PDF page(s): 21 (1-based).
// Host launch configuration and kernel are separate excerpts; numThreadsPerBlock comes from page 12.

const unsigned int numBlocks = (N + numThreadsPerBlock- 1)/numThreadsPerBlock;
__global__ void vecadd_kernel(float* x, float* y, float* z, int N) {
    int i = blockDim.x*blockIdx.x + threadIdx.x;
    if(i < N) {
        z[i] = x[i] + y[i];
    }
}
