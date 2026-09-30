// Source: lectures/Chapter 03 - Multidimensional Grids and Data.pdf
// PDF page(s): 19 (1-based).
// Kernel as shown; BLUR_SIZE is unspecified; out-of-image contributions are zero with a fixed denominator.

__global__ void blur_kernel(unsigned char* image, unsigned char* blurred,
unsigned int width, unsigned int height) {
    int outRow = blockIdx.y*blockDim.y + threadIdx.y;
    int outCol = blockIdx.x*blockDim.x + threadIdx.x;
    if (outRow < height && outCol < width) {
        unsigned int average = 0;
        for(int inRow = outRow - BLUR_SIZE; inRow < outRow + BLUR_SIZE + 1; ++inRow) {
            for(int inCol = outCol - BLUR_SIZE; inCol < outCol + BLUR_SIZE + 1; ++inCol) {
                if(inRow >= 0 && inRow < height && inCol >= 0 && inCol < width) {
                    average += image[inRow*width + inCol];
                }
            }
        }
        blurred[outRow*width + outCol] =
        (unsigned char)(average/((2*BLUR_SIZE + 1)*(2*BLUR_SIZE + 1)));
    }
}
