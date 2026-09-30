// Source: lectures/Chapter 03 - Multidimensional Grids and Data.pdf
// PDF page(s): 13 (1-based).
// Complete kernel as shown; has no boundary check.

__global__ void rgb2gray_kernel(unsigned char* red, unsigned char* green, unsigned char* blue,
unsigned char* gray, unsigned int width, unsigned int height) {
    unsigned int row = blockIdx.y*blockDim.y + threadIdx.y;
    unsigned int col = blockIdx.x*blockDim.x + threadIdx.x;
    // Convert the pixel
    gray[row*width + col] = red[row*width + col]*3/10
    + green[row*width + col]*6/10 + blue[row*width + col]*1/10;
}
