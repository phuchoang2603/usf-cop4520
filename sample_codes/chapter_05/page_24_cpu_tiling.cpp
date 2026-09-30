// Source: lectures/Chapter 05 - Memory Architecture and Data Locality.pdf
// PDF page(s): 24 (1-based).
// CPU loop excerpt; A, B, C, N and TILE_DIM are supplied externally; N must be a multiple of TILE_DIM.

for(unsigned int rowTile = 0; rowTile < N/TILE_DIM; ++rowTile) {
    for(unsigned int colTile = 0; colTile < N/TILE_DIM; ++colTile) {
        for(unsigned int iTile = 0; iTile < N/TILE_DIM; ++iTile) {
            for (unsigned int row = rowTile*TILE_DIM; row < (rowTile + 1)*TILE_DIM; ++row) {
                for (unsigned int col = colTile*TILE_DIM; col < (colTile + 1)*TILE_DIM; ++col) {
                    float sum = 0.0f;
                    for(unsigned int i = iTile*TILE_DIM; i < (iTile + 1)*TILE_DIM; ++i) {
                        sum += A[row*N + i]*B[i*N + col];
                    }
                    if(iTile == 0) {
                        C[row*N + col] = sum;
                    } else {
                        C[row*N + col] += sum;
                    }
                }
            }
        }
    }
}
