// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 3, 4 (1-based).
// Repeated indexing excerpts; array expressions have no semicolons in the slides.

int Row = by * blockDim.y + ty;
int Col = bx * blockDim.x + tx;
// 2D indexing for accessing Tile 0:
M[Row][tx]
N[ty][Col]
