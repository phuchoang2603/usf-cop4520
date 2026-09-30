// Source: lectures/Lecture-Reduction.pdf
// PDF page(s): 13 (1-based).
// Kernel body excerpt; BLOCK_SIZE is unspecified. Slide typo retained: partialSum[blockDim+t] is missing .x.

__shared__ float partialSum[2*BLOCK_SIZE];
unsigned int t = threadIdx.x;
unsigned int start = 2*blockIdx.x*blockDim.x;
partialSum[t] = input[start + t];
partialSum[blockDim+t] = input[start + blockDim.x+t];
