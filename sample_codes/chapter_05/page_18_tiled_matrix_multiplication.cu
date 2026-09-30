// Source: lectures/Chapter 05 - Memory Architecture and Data Locality.pdf
// PDF page(s): 18 (1-based).
// Kernel body excerpt; TILE_DIM is unspecified and N must be a multiple of TILE_DIM; there are no boundary checks.

__shared__ float A_s[TILE_DIM][TILE_DIM];
__shared__ float B_s[TILE_DIM][TILE_DIM];
unsigned int row = blockIdx.y*blockDim.y + threadIdx.y;
unsigned int col = blockIdx.x*blockDim.x + threadIdx.x;
float sum = 0.0f;
for(unsigned int tile = 0; tile < N/TILE_DIM; ++tile) {
    // Load tile to shared memory
    A_s[threadIdx.y][threadIdx.x] = A[row*N + tile*TILE_DIM + threadIdx.x];
    B_s[threadIdx.y][threadIdx.x] = B[(tile*TILE_DIM + threadIdx.y)*N + col];
    __syncthreads();
    // Compute with tile
    for(unsigned int i = 0; i < TILE_DIM; ++i) {
        sum += A_s[threadIdx.y][i]*B_s[i][threadIdx.x];
    }
    __syncthreads();
}
C[row*N + col] = sum;
