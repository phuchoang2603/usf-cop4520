// Source: lectures/Lecture-Reduction.pdf
// PDF page(s): 20 (1-based).
// Alternative reduction loop using the page 13 setup; block size is assumed to be a power of two. No output-store code is shown.

for (unsigned int stride = blockDim.x;
stride > 0; stride /= 2)
{
    __syncthreads();
    if (t < stride)
    partialSum[t] += partialSum[t+stride];
}
