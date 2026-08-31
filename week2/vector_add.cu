#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <vector>

#define CUDA_CHECK(call)                                                       \
  do {                                                                         \
    cudaError_t err = (call);                                                  \
    if (err != cudaSuccess) {                                                  \
      std::fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,    \
                   cudaGetErrorString(err));                                   \
      std::exit(EXIT_FAILURE);                                                 \
    }                                                                          \
  } while (0)

constexpr int N = 1 << 20; // 1,048,576 elements
constexpr int THREADS = 256;

__global__ void vectorAdd(const float *a, const float *b, float *c, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) {
    c[i] = a[i] + b[i];
  }
}

int main() {
  const size_t bytes = static_cast<size_t>(N) * sizeof(float);

  std::vector<float> h_a(N), h_b(N), h_c(N);
  for (int i = 0; i < N; ++i) {
    h_a[i] = static_cast<float>(i);
    h_b[i] = static_cast<float>(i * 2);
  }

  float *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;
  CUDA_CHECK(cudaMalloc(&d_a, bytes));
  CUDA_CHECK(cudaMalloc(&d_b, bytes));
  CUDA_CHECK(cudaMalloc(&d_c, bytes));

  CUDA_CHECK(cudaMemcpy(d_a, h_a.data(), bytes, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_b, h_b.data(), bytes, cudaMemcpyHostToDevice));

  int blocks = (N + THREADS - 1) / THREADS;
  vectorAdd<<<blocks, THREADS>>>(d_a, d_b, d_c, N);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());

  CUDA_CHECK(cudaMemcpy(h_c.data(), d_c, bytes, cudaMemcpyDeviceToHost));

  int mismatches = 0;
  for (int i = 0; i < N; ++i) {
    float expected = h_a[i] + h_b[i];
    if (h_c[i] != expected) {
      if (mismatches < 8) {
        std::fprintf(stderr, "mismatch at %d: got %f expected %f\n", i, h_c[i],
                     expected);
      }
      ++mismatches;
    }
  }

  CUDA_CHECK(cudaFree(d_a));
  CUDA_CHECK(cudaFree(d_b));
  CUDA_CHECK(cudaFree(d_c));

  if (mismatches != 0) {
    std::fprintf(stderr, "FAILED: %d / %d elements incorrect\n", mismatches, N);
    return EXIT_FAILURE;
  }

  std::printf("vectorAdd OK: %d elements (c[0]=%.0f, c[N-1]=%.0f)\n", N, h_c[0],
              h_c[N - 1]);
  return EXIT_SUCCESS;
}
