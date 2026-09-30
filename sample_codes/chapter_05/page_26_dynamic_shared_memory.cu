// Source: lectures/Chapter 05 - Memory Architecture and Data Locality.pdf
// PDF page(s): 26 (1-based).
// Declaration and launch excerpts as shown; the slide omits the shared array element type and uses ... for kernel arguments.

extern __shared__ A_s[];
kernel <<< numBlocks, numThreadsPerBlock, smemPerBlock >>> (...)
