// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 25 (1-based).
// Partial kernel edit as shown; slide list markers and line numbers removed. Slide typo retained: t in the M boundary condition.

for (int p = 0; p < (Width-1) / TILE_WIDTH + 1; ++p) {
    if(Row < Width && t * TILE_WIDTH+tx < Width) {
        ds_M[ty][tx] = M[Row * Width + p * TILE_WIDTH + tx];
    } else {
        ds_M[ty][tx] = 0.0;
    }
    if (p*TILE_WIDTH+ty < Width && Col < Width) {
        ds_N[ty][tx] = N[(p*TILE_WIDTH + ty) * Width + Col];
    } else {
        ds_N[ty][tx] = 0.0;
    }
    __syncthreads();
