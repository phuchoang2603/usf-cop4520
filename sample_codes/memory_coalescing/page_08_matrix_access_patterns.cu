// Source: lectures/Lecture-memory-coalescing.pdf
// PDF page(s): 8 (1-based).
// Index-expression excerpts as shown; A is m by n, B is n by k; missing semicolons are retained.

A[Row*n+i]
B[i*k+Col]
Col = blockIdx.x*blockDim.x + threadIdx.x
