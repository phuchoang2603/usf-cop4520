// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 5, 6 (1-based).
// Repeated index expressions as shown; slide typo retained: TILE*WIDTH instead of TILE_WIDTH.

M[Row][1*TILE_WIDTH + tx]
N[1*TILE*WIDTH + ty][Col]
