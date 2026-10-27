#include <sys/time.h>
#include <chrono>
#include <vector>
#define main proj2_submission_main
#include "../proj2.cu"
#undef main
namespace project1 {
#define main proj1_submission_main
#include "../../proj1/proj1-phuchoang.cu"
#undef main
}

int main() {
  const int block = 128;
  const double width = 256;
  const int bins = (int)(BOX_SIZE * sqrt(3.0) / width) + 1;
  const size_t hist_bytes = bins * sizeof(bucket);
  cudaDeviceProp device;
  check_cuda(cudaGetDeviceProperties(&device, 0));
  printf("GPU: %s\nShared memory per block: %zu\n", device.name, device.sharedMemPerBlock);
  printf("Width: 256; block: 128; seed: 1; GPU trials: 3; CPU trials: 1\n");
  fflush(stdout);
  int sizes[] = {10000, 100000, 500000};
  for (int size_index = 0; size_index < 3; size_index++) {
    int n = sizes[size_index];
    project1::PDH_acnt = n;
    project1::PDH_res = width;
    project1::num_buckets = bins;
    project1::atom_list = (project1::atom *)malloc(n * sizeof(project1::atom));
    project1::histogram = (project1::bucket *)calloc(bins, sizeof(project1::bucket));
    if (!project1::atom_list || !project1::histogram) return 1;
    srand(1);
    for (int i = 0; i < n; i++) {
      project1::atom_list[i].x_pos = ((double)rand() / RAND_MAX) * BOX_SIZE;
      project1::atom_list[i].y_pos = ((double)rand() / RAND_MAX) * BOX_SIZE;
      project1::atom_list[i].z_pos = ((double)rand() / RAND_MAX) * BOX_SIZE;
    }
    std::vector<bucket> reference(bins), result(bins);
    if (n <= 100000) {
      auto start = std::chrono::steady_clock::now();
      project1::PDH_baseline();
      double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
      printf("CPU,%d,%.9f\n", n, seconds);
      for (int b = 0; b < bins; b++) reference[b] = project1::histogram[b].d_cnt;
    } else {
      printf("CPU,%d,N/A\n", n);
    }
    fflush(stdout);
    atom *d_points;
    bucket *d_hist;
    check_cuda(cudaMalloc((void **)&d_points, n * sizeof(atom)));
    check_cuda(cudaMalloc((void **)&d_hist, hist_bytes));
    check_cuda(cudaMemcpy(d_points, project1::atom_list, n * sizeof(atom), cudaMemcpyHostToDevice));
    int tiles = (n + block - 1) / block;
    const char *names[] = {"Project1-global", "Project1-shared", "Project2-tiled"};
    for (int version = 0; version < 3; version++) {
      double sum = 0;
      for (int trial = 0; trial < 3; trial++) {
        check_cuda(cudaMemset(d_hist, 0, hist_bytes));
        cudaEvent_t start, stop;
        check_cuda(cudaEventCreate(&start));
        check_cuda(cudaEventCreate(&stop));
        check_cuda(cudaEventRecord(start, 0));
        if (version == 0)
          project1::PDH_kernel_global<<<tiles, block>>>((project1::atom *)d_points, (project1::bucket *)d_hist, n, width);
        else if (version == 1)
          project1::PDH_kernel_shared<<<tiles, block, hist_bytes>>>((project1::atom *)d_points, (project1::bucket *)d_hist, n, width, bins);
        else
          PDH_kernel<<<dim3(tiles, tiles), block, block * sizeof(atom) + hist_bytes>>>(d_points, d_hist, n, width, bins, true);
        check_cuda(cudaGetLastError());
        check_cuda(cudaEventRecord(stop, 0));
        check_cuda(cudaEventSynchronize(stop));
        float ms;
        check_cuda(cudaEventElapsedTime(&ms, start, stop));
        check_cuda(cudaEventDestroy(start));
        check_cuda(cudaEventDestroy(stop));
        check_cuda(cudaMemcpy(result.data(), d_hist, hist_bytes, cudaMemcpyDeviceToHost));
        if (n == 500000 && version == 0 && trial == 0) reference = result;
        bucket total = 0;
        for (int b = 0; b < bins; b++) {
          if (result[b] != reference[b]) {
            fprintf(stderr, "Histogram mismatch: n=%d version=%s trial=%d bucket=%d\n", n, names[version], trial, b);
            return 1;
          }
          total += result[b];
        }
        if (total != (bucket)n * (n - 1) / 2) return 1;
        sum += ms / 1000.0;
        printf("TRIAL,%s,%d,%d,%.9f,PASS\n", names[version], n, trial + 1, ms / 1000.0);
        fflush(stdout);
      }
      printf("MEAN,%s,%d,%.9f\n", names[version], n, sum / 3);
      fflush(stdout);
    }
    check_cuda(cudaFree(d_points));
    check_cuda(cudaFree(d_hist));
    free(project1::atom_list);
    free(project1::histogram);
  }
  printf("ALL BENCHMARKS PASSED\n");
  return 0;
}
