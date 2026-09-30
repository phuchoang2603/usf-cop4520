// Source: lectures/Chapter 02 - Heterogeneous Data Parallel Computing.pdf
// PDF page(s): 27 (1-based).
// API signature and error-checking snippet; ... is the slide placeholder for a CUDA call.

cudaError_t cudaGetLastError()
cudaError_t err = ...;
if(err != cudaSuccess) {
    printf("Error: %s\n"
    , cudaGetErrorString(err));
    exit(0);
}
