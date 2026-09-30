// Source: lectures/Chapter 03 - Multidimensional Grids and Data.pdf
// PDF page(s): 10 (1-based).
// Incomplete kernel; ... is the slide placeholder for pixel conversion.

__global__ void rgb2gray_kernel(unsigned char* red, unsigned char* green, unsigned char* blue,
unsigned char* gray, unsigned int width, unsigned int height) {
    unsigned int row = blockIdx.y*blockDim.y + threadIdx.y;
    unsigned int col = blockIdx.x*blockDim.x + threadIdx.x;
    // Convert the pixel
    ...
}
