// Source: lectures/Lecture-Reduction.pdf
// PDF page(s): 14 (1-based).
// Kernel body excerpt; uses t and partialSum from page 13. Block size is assumed to be a power of two.

for (unsigned int stride = 1;
stride <= blockDim.x; stride *= 2)
{
    __syncthreads();
    if (t % stride == 0)
    partialSum[2*t]+= partialSum[2*t+stride];
}
