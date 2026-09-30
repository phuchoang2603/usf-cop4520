// Source: lectures/Lecture-warps-divergence.pdf
// PDF page(s): 10 (1-based).
// Complete kernel as shown; no host code or main function is supplied.

// Compute vector sum C = A + B
// Each thread performs one pair-wise addition
__global__
void vecAddKernel(float* A, float* B, float* C,
int n)
{
    int i = threadIdx.x + blockDim.x * blockIdx.x;
    if(i<n) C[i] = A[i] + B[i];
}
