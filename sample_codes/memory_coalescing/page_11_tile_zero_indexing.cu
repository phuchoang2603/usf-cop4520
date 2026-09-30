// Source: lectures/Lecture-memory-coalescing.pdf
// PDF page(s): 11 (1-based).
// Indexing excerpts as shown; missing semicolons are retained.

int tx = threadIdx.x
int ty = threadIdx.y

A[Row][tx]
B[ty][Col]
