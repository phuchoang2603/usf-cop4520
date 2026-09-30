// Source: lectures/Chapter 05 - Memory Architecture and Data Locality.pdf
// PDF page(s): 5 (1-based).
// Slide excerpt; surrounding declarations or host code may be required.

for(unsigned int i = 0; i < N; ++i) {
    sum += A[row*N + i]*B[i*N + col];
}
