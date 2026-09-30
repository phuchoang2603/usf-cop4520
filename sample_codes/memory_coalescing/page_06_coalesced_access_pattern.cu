// Source: lectures/Lecture-memory-coalescing.pdf
// PDF page(s): 6 (1-based).
// Pseudocode access pattern; the parenthesized English text is a placeholder.

A[(expression with terms independent of threadIdx.x) + threadIdx.x];
