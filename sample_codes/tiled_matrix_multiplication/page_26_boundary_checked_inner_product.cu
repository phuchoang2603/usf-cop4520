// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 26 (1-based).
// Partial kernel edit as shown; slide list markers and line numbers removed. The added Row/Col if statement has no matching closing brace in the slide; no missing code was invented.

if(Row < Width && Col < Width) {
    for (int i = 0; i < TILE_WIDTH; ++i) {
        Pvalue += ds_M[ty][i] * ds_N[i][tx];
    }
    __syncthreads();
} /* end of outer for loop */
if (Row < Width && Col < Width)
P[Row*Width + Col] = Pvalue;
} /* end of kernel */
