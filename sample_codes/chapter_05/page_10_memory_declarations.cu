// Source: lectures/Chapter 05 - Memory Architecture and Data Locality.pdf
// PDF page(s): 10 (1-based).
// Individual declaration examples from the table; each belongs in its appropriate scope, and N is unspecified.

__device__ int globalVar;
__device__ __constant__ int constantVar;
__device__ __shared__ int sharedVar;
int localVar;
int localArr[N];
