/* ==================================================================
        Based on Yicheng Tu's Project 1 SDH starter program.
        Programmer: Felix Hoang
   ==================================================================
*/

#include <errno.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define BOX_SIZE 23000

typedef struct atomdesc {
  double x_pos, y_pos, z_pos;
} atom;

typedef unsigned long long bucket;

void check_cuda(cudaError_t error) {
  if (error != cudaSuccess) {
    fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(error));
    exit(1);
  }
}

__global__ void PDH_kernel(const atom *points, bucket *histogram, int n,
                           double width, int num_buckets, bool use_shared) {
  extern __shared__ bucket shared[];
  atom *tile = (atom *)shared;
  bucket *local_histogram =
      shared + (sizeof(atom) * blockDim.x) / sizeof(bucket);
  int tid = threadIdx.x;
  long long i = (long long)blockIdx.x * blockDim.x + tid;
  atom point = {0.0, 0.0, 0.0};
  if (i < n)
    point = points[i];

  if (use_shared) {
    for (int b = tid; b < num_buckets; b += blockDim.x)
      local_histogram[b] = 0;
  }
  __syncthreads();

  int num_tiles = (int)(((long long)n + blockDim.x - 1) / blockDim.x);
  for (int t = blockIdx.y; t < num_tiles; t += gridDim.y) {
    if (t < blockIdx.x)
      continue;
    long long first = (long long)t * blockDim.x;
    if (first + tid < n)
      tile[tid] = points[first + tid];
    __syncthreads();

    int count = n - first < blockDim.x ? (int)(n - first) : (int)blockDim.x;
    if (i < n) {
      for (int j = 0; j < count; j++) {
        if (first + j <= i)
          continue;
        double dx = point.x_pos - tile[j].x_pos;
        double dy = point.y_pos - tile[j].y_pos;
        double dz = point.z_pos - tile[j].z_pos;
        // Match the CPU's separate multiply/add rounding at bucket boundaries.
        double squared = __dadd_rn(
            __dadd_rn(__dmul_rn(dx, dx), __dmul_rn(dy, dy)), __dmul_rn(dz, dz));
        int b = (int)(sqrt(squared) / width);
        atomicAdd(use_shared ? &local_histogram[b] : &histogram[b], 1ULL);
      }
    }
    __syncthreads();
  }

  if (use_shared) {
    for (int b = tid; b < num_buckets; b += blockDim.x) {
      if (local_histogram[b] != 0)
        atomicAdd(&histogram[b], local_histogram[b]);
    }
  }
}

void output_histogram(const bucket *histogram, int num_buckets) {
  bucket total = 0;
  for (int b = 0; b < num_buckets; b++) {
    if (b % 5 == 0)
      printf("\n%02d: ", b);
    printf("%15llu ", histogram[b]);
    total += histogram[b];
    if (b != num_buckets - 1)
      printf("| ");
  }
  printf("\n T:%llu\n", total);
}

bool parse_integer(const char *text, int *value) {
  char *end;
  errno = 0;
  long parsed = strtol(text, &end, 10);
  if (errno || end == text || *end != '\0' || parsed < 1 || parsed > INT_MAX)
    return false;
  *value = (int)parsed;
  return true;
}

int main(int argc, char **argv) {
  int n, block_size;
  if (argc != 4 || !parse_integer(argv[1], &n) ||
      !parse_integer(argv[3], &block_size)) {
    fprintf(stderr,
            "Usage: %s samples bucket_width block_size (positive values)\n",
            argv[0]);
    return 1;
  }

  char *end;
  errno = 0;
  double width = strtod(argv[2], &end);
  if (errno || end == argv[2] || *end != '\0' || !isfinite(width) ||
      width <= 0) {
    fprintf(stderr, "Bucket width must be a positive finite number.\n");
    return 1;
  }
  double bucket_count = floor(BOX_SIZE * sqrt(3.0) / width) + 1.0;
  if (!isfinite(bucket_count) || bucket_count > INT_MAX) {
    fprintf(stderr, "Bucket width is too small.\n");
    return 1;
  }
  int num_buckets = (int)bucket_count;

  cudaDeviceProp device;
  check_cuda(cudaGetDeviceProperties(&device, 0));
  if (block_size > device.maxThreadsPerBlock ||
      block_size > device.maxThreadsDim[0]) {
    fprintf(stderr, "Block size exceeds the GPU limit.\n");
    return 1;
  }
  size_t tile_bytes = sizeof(atom) * (size_t)block_size;
  size_t histogram_bytes = sizeof(bucket) * (size_t)num_buckets;
  if (tile_bytes > device.sharedMemPerBlock) {
    fprintf(stderr, "Point tile exceeds shared memory capacity.\n");
    return 1;
  }
  bool use_shared = histogram_bytes <= device.sharedMemPerBlock - tile_bytes;
  size_t shared_bytes = tile_bytes + (use_shared ? histogram_bytes : 0);
  int num_tiles = (int)(((long long)n + block_size - 1) / block_size);
  if (num_tiles > device.maxGridSize[0]) {
    fprintf(stderr, "Sample count exceeds the GPU grid limit.\n");
    return 1;
  }
  dim3 grid(num_tiles, num_tiles < device.maxGridSize[1]
                           ? num_tiles
                           : device.maxGridSize[1]);

  atom *points = (atom *)malloc(sizeof(atom) * (size_t)n);
  bucket *cpu_histogram = (bucket *)calloc(num_buckets, sizeof(bucket));
  bucket *gpu_histogram = (bucket *)malloc(histogram_bytes);
  if (!points || !cpu_histogram || !gpu_histogram) {
    fprintf(stderr, "Not enough host memory.\n");
    free(points);
    free(cpu_histogram);
    free(gpu_histogram);
    return 1;
  }
  srand(1);
  for (int i = 0; i < n; i++) {
    points[i].x_pos = ((double)rand() / RAND_MAX) * BOX_SIZE;
    points[i].y_pos = ((double)rand() / RAND_MAX) * BOX_SIZE;
    points[i].z_pos = ((double)rand() / RAND_MAX) * BOX_SIZE;
  }
  for (int i = 0; i < n; i++) {
    for (int j = i + 1; j < n; j++) {
      double dx = points[i].x_pos - points[j].x_pos;
      double dy = points[i].y_pos - points[j].y_pos;
      double dz = points[i].z_pos - points[j].z_pos;
      int b = (int)(sqrt(dx * dx + dy * dy + dz * dz) / width);
      cpu_histogram[b]++;
    }
  }

  atom *d_points;
  bucket *d_histogram;
  check_cuda(cudaMalloc((void **)&d_points, sizeof(atom) * (size_t)n));
  check_cuda(cudaMalloc((void **)&d_histogram, histogram_bytes));
  check_cuda(cudaMemcpy(d_points, points, sizeof(atom) * (size_t)n,
                        cudaMemcpyHostToDevice));
  check_cuda(cudaMemset(d_histogram, 0, histogram_bytes));

  cudaEvent_t start, stop;
  check_cuda(cudaEventCreate(&start));
  check_cuda(cudaEventCreate(&stop));
  check_cuda(cudaEventRecord(start, 0));
  PDH_kernel<<<grid, block_size, shared_bytes>>>(
      d_points, d_histogram, n, width, num_buckets, use_shared);
  check_cuda(cudaGetLastError());
  check_cuda(cudaEventRecord(stop, 0));
  check_cuda(cudaEventSynchronize(stop));
  float milliseconds;
  check_cuda(cudaEventElapsedTime(&milliseconds, start, stop));
  check_cuda(cudaMemcpy(gpu_histogram, d_histogram, histogram_bytes,
                        cudaMemcpyDeviceToHost));

  printf("CPU histogram:\n");
  output_histogram(cpu_histogram, num_buckets);
  printf("\nOptimized GPU histogram:\n");
  output_histogram(gpu_histogram, num_buckets);
  printf("\nDifferences (CPU - GPU):\n");
  bool match = true;
  for (int b = 0; b < num_buckets; b++) {
    if (b % 5 == 0)
      printf("\n%02d: ", b);
    long long difference =
        (long long)cpu_histogram[b] - (long long)gpu_histogram[b];
    printf("%15lld ", difference);
    if (b != num_buckets - 1)
      printf("| ");
    if (difference != 0)
      match = false;
  }
  printf("\n\n******** Total Kernel Execution Time = %.6f sec *******\n",
         milliseconds / 1000.0);

  check_cuda(cudaEventDestroy(start));
  check_cuda(cudaEventDestroy(stop));
  check_cuda(cudaFree(d_points));
  check_cuda(cudaFree(d_histogram));
  free(points);
  free(cpu_histogram);
  free(gpu_histogram);
  return match ? 0 : 1;
}
