// Source: lectures/Chapter 03 - Multidimensional Grids and Data.pdf
// PDF page(s): 14 (1-based).
// Complete kernel as shown; checks both image dimensions.

__global__ void rgb2gray_kernel(unsigned char* red, unsigned char* green, unsigned char* blue,
unsigned char* gray, unsigned int width, unsigned int height) {
    unsigned int row = blockIdx.y*blockDim.y + threadIdx.y;
    unsigned int col = blockIdx.x*blockDim.x + threadIdx.x;
    // Convert the pixel
    if (row < height && col < width) {
        gray[row*width + col] = red[row*width + col]*3/10
        + green[row*width + col]*6/10 + blue[row*width + col]/10;
    }
}
