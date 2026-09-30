// Source: lectures/Chapter 02 - Heterogeneous Data Parallel Computing.pdf
// PDF page(s): 7 (1-based).
// API signature as shown; trailing semicolon is omitted in the slide.

cudaError_t cudaMemcpy(void *dst, const void *src,
size_t count, enum cudaMemcpyKind kind)

// cudaMemcpyKind values shown:
// cudaMemcpyHostToHost
// cudaMemcpyHostToDevice
// cudaMemcpyDeviceToHost
// cudaMemcpyDeviceToDevice
