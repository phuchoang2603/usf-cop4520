#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

#define BOX_SIZE 23000 /* size of the data box on one dimension            */

/* descriptors for single atom in the tree */
typedef struct atomdesc
{
	double x_pos;
	double y_pos;
	double z_pos;
} atom;

typedef struct hist_entry
{
	// float min;
	// float max;
	long long d_cnt; /* need a long long type as the count might be huge */
} bucket;

bucket *histogram;	/* list of all buckets in the histogram   */
long long PDH_acnt; /* total number of data points            */
int num_buckets;	/* total number of buckets in the histogram */
double PDH_res;		/* value of w                             */
atom *atom_list;	/* list of all data points                */

/* These are for an old way of tracking time */
struct timezone Idunno;
struct timeval startTime, endTime;

/*
	distance of two points in the atom_list
*/
double p2p_distance(int ind1, int ind2)
{

	double x1 = atom_list[ind1].x_pos;
	double x2 = atom_list[ind2].x_pos;
	double y1 = atom_list[ind1].y_pos;
	double y2 = atom_list[ind2].y_pos;
	double z1 = atom_list[ind1].z_pos;
	double z2 = atom_list[ind2].z_pos;

	return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2));
}

/*
	brute-force SDH solution in a single CPU thread
*/
int PDH_baseline()
{
	int i, j, h_pos;
	double dist;

	for (i = 0; i < PDH_acnt; i++)
	{
		for (j = i + 1; j < PDH_acnt; j++)
		{
			dist = p2p_distance(i, j);
			h_pos = (int)(dist / PDH_res);
			histogram[h_pos].d_cnt++;
		}
	}
	return 0;
}

/*
	set a checkpoint and show the (natural) running time in seconds
*/
double report_running_time()
{
	long sec_diff, usec_diff;
	gettimeofday(&endTime, &Idunno);
	sec_diff = endTime.tv_sec - startTime.tv_sec;
	usec_diff = endTime.tv_usec - startTime.tv_usec;
	if (usec_diff < 0)
	{
		sec_diff--;
		usec_diff += 1000000;
	}
	printf("Running time for CPU version: %ld.%06ld\n", sec_diff, usec_diff);
	return (double)(sec_diff * 1.0 + usec_diff / 1000000.0);
}

/*
	print the counts in all buckets of the histogram
*/
void output_histogram(bucket *histogram, int num_buckets)
{
	int i;
	long long total_cnt = 0;
	for (i = 0; i < num_buckets; i++)
	{
		if (i % 5 == 0) /* we print 5 buckets in a row */
			printf("\n%02d: ", i);
		printf("%15lld ", histogram[i].d_cnt);
		total_cnt += histogram[i].d_cnt;
		/* we also want to make sure the total distance count is correct */
		if (i == num_buckets - 1)
			printf("\n T:%lld \n", total_cnt);
		else
			printf("| ");
	}
}

/* Compare CPU and GPU histograms and print the difference histogram */
bool compare_histograms(bucket *cpu_hist, bucket *gpu_hist)
{
	bool match = true;
	printf("\nDifference between CPU and GPU histograms:\n");
	for (int i = 0; i < num_buckets; i++)
	{
		long long diff = cpu_hist[i].d_cnt - gpu_hist[i].d_cnt;
		if (diff != 0)
			match = false;
		if (i % 5 == 0)
			printf("\n%02d: ", i);
		printf("%15lld ", diff);
		if (i != num_buckets - 1)
			printf("| ");
	}
	printf("\n");
	return match;
}

__global__ void global_kernel(const atom *d_atom_list, long long atom_count, double bucket_width, bucket *d_histogram, int num_buckets)
{
	long long i = (long long)blockIdx.x * blockDim.x + threadIdx.x;
	if (i < atom_count)
	{
		for (long long j = i + 1; j < atom_count; j++)
		{
			double dx = d_atom_list[i].x_pos - d_atom_list[j].x_pos;
			double dy = d_atom_list[i].y_pos - d_atom_list[j].y_pos;
			double dz = d_atom_list[i].z_pos - d_atom_list[j].z_pos;
			double dist = sqrt(dx * dx + dy * dy + dz * dz);
			int h_pos = (int)(dist / bucket_width);
			if (h_pos < num_buckets)
			{
				atomicAdd((unsigned long long *)&(d_histogram[h_pos].d_cnt), 1ULL);
			}
		}
	}
}

__global__ void shared_kernel(const atom *d_atom_list, long long atom_count, double bucket_width, bucket *d_histogram, int num_buckets)
{
	extern __shared__ bucket shared_histogram[];

	long long i = (long long)blockIdx.x * blockDim.x + threadIdx.x;
	for (int h = threadIdx.x; h < num_buckets; h += blockDim.x)
	{
		shared_histogram[h].d_cnt = 0;
	}

	__syncthreads();

	if (i < atom_count)
	{
		for (long long j = i + 1; j < atom_count; j++)
		{
			double dx = d_atom_list[i].x_pos - d_atom_list[j].x_pos;
			double dy = d_atom_list[i].y_pos - d_atom_list[j].y_pos;
			double dz = d_atom_list[i].z_pos - d_atom_list[j].z_pos;
			double dist = sqrt(dx * dx + dy * dy + dz * dz);
			int h_pos = (int)(dist / bucket_width);
			if (h_pos < num_buckets)
			{
				atomicAdd((unsigned long long *)&(shared_histogram[h_pos].d_cnt), 1ULL);
			}
		}
	}

	__syncthreads();

	for (int h = threadIdx.x; h < num_buckets; h += blockDim.x)
	{
		long long local_count = shared_histogram[h].d_cnt;
		if (local_count > 0)
		{
			atomicAdd((unsigned long long *)&(d_histogram[h].d_cnt), (unsigned long long)local_count);
		}
	}
}

int main(int argc, char **argv)
{
	int i;

	PDH_acnt = atoi(argv[1]); // number of particles
	PDH_res = atof(argv[2]);  // bucket width = w
	// printf("args are %d and %f\n", PDH_acnt, PDH_res);

	num_buckets = (int)(BOX_SIZE * 1.732 / PDH_res) + 1;
	histogram = (bucket *)calloc(num_buckets, sizeof(bucket));

	atom_list = (atom *)malloc(sizeof(atom) * PDH_acnt);

	srand(1);
	/* generate data following a uniform distribution */
	for (i = 0; i < PDH_acnt; i++)
	{
		atom_list[i].x_pos = ((double)(rand()) / RAND_MAX) * BOX_SIZE;
		atom_list[i].y_pos = ((double)(rand()) / RAND_MAX) * BOX_SIZE;
		atom_list[i].z_pos = ((double)(rand()) / RAND_MAX) * BOX_SIZE;
	}

	// declare device pointers
	atom *d_atom_list = NULL;
	bucket *d_histogram = NULL;

	// allocate GPU memory
	cudaMalloc((void **)&d_atom_list, sizeof(atom) * PDH_acnt);
	cudaMalloc((void **)&d_histogram, sizeof(bucket) * num_buckets);

	// initialize histogram to 0
	cudaMemset(d_histogram, 0, sizeof(bucket) * num_buckets);

	// copy data to GPU memory
	cudaMemcpy(d_atom_list, atom_list, sizeof(atom) * PDH_acnt, cudaMemcpyHostToDevice);

	/* start counting time */
	gettimeofday(&startTime, &Idunno);

	/* call CPU single thread version to compute the histogram */
	PDH_baseline();

	/* check the total running time */
	report_running_time();

	/* print out the histogram */
	printf("\nCPU histogram:\n");
	output_histogram(histogram, num_buckets);

	// configure kernel launch parameters
	int numThreadsPerBlock = 256;
	int numBlocks = (PDH_acnt + numThreadsPerBlock - 1) / numThreadsPerBlock;

	// GPU timer events
	cudaEvent_t start_event;
	cudaEvent_t stop_event;

	cudaEventCreate(&start_event);
	cudaEventCreate(&stop_event);
	cudaEventRecord(start_event);

	// launch the kernel
	global_kernel<<<numBlocks, numThreadsPerBlock>>>(d_atom_list, PDH_acnt, PDH_res, d_histogram, num_buckets);

	// check for kernel launch errors
	cudaError_t err = cudaGetLastError();
	if (err != cudaSuccess)
	{
		printf("Global Kernel Error: %s\n", cudaGetErrorString(err));
	}

	cudaEventRecord(stop_event);
	cudaEventSynchronize(stop_event);

	// get the elapsed time
	float global_kernel_time = 0;
	cudaEventElapsedTime(&global_kernel_time, start_event, stop_event);
	printf("Global Kernel Time: %f ms\n", global_kernel_time);

	// allocate memory for the GPU histogram
	bucket *global_gpu_histogram = (bucket *)calloc(num_buckets, sizeof(bucket));

	// copy the GPU histogram back to host
	cudaMemcpy(global_gpu_histogram, d_histogram, sizeof(bucket) * num_buckets, cudaMemcpyDeviceToHost);

	// print the GPU histogram
	printf("\nGlobal GPU histogram:\n");
	output_histogram(global_gpu_histogram, num_buckets);

	// compare CPU and GPU histograms
	bool global_correct = compare_histograms(histogram, global_gpu_histogram);
	printf("Global GPU Correctness: %s\n", global_correct ? "PASS" : "FAIL");

	// reset the GPU histogram to 0 for part B
	cudaMemset(d_histogram, 0, sizeof(bucket) * num_buckets);

	cudaEventRecord(start_event);

	// launch the shared memory kernel
	shared_kernel<<<numBlocks, numThreadsPerBlock, sizeof(bucket) * num_buckets>>>(d_atom_list, PDH_acnt, PDH_res, d_histogram, num_buckets);

	// check for kernel launch errors
	cudaError_t shared_err = cudaGetLastError();
	if (shared_err != cudaSuccess)
	{
		printf("Shared Kernel Error: %s\n", cudaGetErrorString(shared_err));
	}

	cudaEventRecord(stop_event);
	cudaEventSynchronize(stop_event);

	// get the elapsed time
	float shared_kernel_time = 0;
	cudaEventElapsedTime(&shared_kernel_time, start_event, stop_event);
	printf("Shared Kernel Time: %f ms\n", shared_kernel_time);

	// allocate memory for the shared GPU histogram
	bucket *shared_gpu_histogram = (bucket *)calloc(num_buckets, sizeof(bucket));

	// copy the shared GPU histogram back to host
	cudaMemcpy(shared_gpu_histogram, d_histogram, sizeof(bucket) * num_buckets, cudaMemcpyDeviceToHost);

	// print the shared GPU histogram
	printf("\nShared-memory GPU histogram:\n");
	output_histogram(shared_gpu_histogram, num_buckets);

	// compare CPU and shared GPU histograms
	bool shared_correct = compare_histograms(histogram, shared_gpu_histogram);
	printf("Shared GPU Correctness: %s\n", shared_correct ? "PASS" : "FAIL");

	cudaFree(d_atom_list);
	cudaFree(d_histogram);

	cudaEventDestroy(start_event);
	cudaEventDestroy(stop_event);

	free(shared_gpu_histogram);
	free(global_gpu_histogram);
	free(atom_list);
	free(histogram);

	return 0;
}
