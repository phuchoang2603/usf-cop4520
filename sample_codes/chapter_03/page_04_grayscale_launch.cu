// Source: lectures/Chapter 03 - Multidimensional Grids and Data.pdf
// PDF page(s): 4 (1-based).
// Host launch snippet; device arrays and image dimensions must already exist.

dim3 numThreadsPerBlock(32, 32);
dim3 numBlocks((width + numThreadsPerBlock.x - 1)/numThreadsPerBlock.x,
(height + numThreadsPerBlock.y - 1)/numThreadsPerBlock.y);
rgb2gray_kernel <<< numBlocks, numThreadsPerBlock >>>
(red_d, green_d, blue_d, gray_d, width, height);
