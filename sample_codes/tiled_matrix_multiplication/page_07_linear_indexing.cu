// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 7 (1-based).
// Pairs of 2D and equivalent 1D index expressions as shown; p is the tile phase.

M[Row][p*TILE_WIDTH+tx]
M[Row*Width + p*TILE_WIDTH + tx]
N[p*TILE_WIDTH+ty][Col]
N[(p*TILE_WIDTH+ty)*Width + Col]
