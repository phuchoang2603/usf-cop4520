// Source: lectures/Chapter 04 - Compute Architecture and Scheduling.pdf
// PDF page(s): 21 (1-based).
// API signature and independent host query snippet as shown.

cudaError_t cudaGetDeviceProperties(cudaDeviceProp* prop,
int device)

int devID = 0;
cudaDeviceProp devProp;
cudaGetDeviceProperties(&devProp, devID);
int maxThreadsPerBlock = devProp.maxThreadsPerBlock;
int maxThreadsPerMultiProcessor =
devProp.maxThreadsPerMultiProcessor;
