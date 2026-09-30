/* ==================================================================
	Programmer: Yicheng Tu (ytu@cse.usf.edu)
	The basic SDH algorithm implementation for 3D data
	To compile: nvcc SDH.c -o SDH in the GAIVI machines
   ==================================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>


#define BOX_SIZE	23000 /* size of the data box on one dimension            */

/* descriptors for single atom in the tree */
typedef struct atomdesc {
	double x_pos;
	double y_pos;
	double z_pos;
} atom;

typedef struct hist_entry{
	//float min;
	//float max;
	long long d_cnt;   /* need a long long type as the count might be huge */
} bucket;


bucket * histogram;		/* list of all buckets in the histogram   */
long long	PDH_acnt;	/* total number of data points            */
int num_buckets;		/* total number of buckets in the histogram */
double   PDH_res;		/* value of w                             */
atom * atom_list;		/* list of all data points                */

atom * d_atom_list;		/* data points on the GPU                 */
bucket * d_histogram;	/* histogram on the GPU                   */
bucket * gpu_histogram;	/* GPU histogram copied back to the host  */
int block_size = 256;	/* threads per block                      */
int num_blocks;			/* blocks in the grid                     */

/* These are for an old way of tracking time */
struct timezone Idunno;	
struct timeval startTime, endTime;


/* 
	distance of two points in the atom_list 
*/
double p2p_distance(int ind1, int ind2) {
	
	double x1 = atom_list[ind1].x_pos;
	double x2 = atom_list[ind2].x_pos;
	double y1 = atom_list[ind1].y_pos;
	double y2 = atom_list[ind2].y_pos;
	double z1 = atom_list[ind1].z_pos;
	double z2 = atom_list[ind2].z_pos;
		
	return sqrt((x1 - x2)*(x1-x2) + (y1 - y2)*(y1 - y2) + (z1 - z2)*(z1 - z2));
}


/* 
	brute-force SDH solution in a single CPU thread 
*/
int PDH_baseline() {
	int i, j, h_pos;
	double dist;
	
	for(i = 0; i < PDH_acnt; i++) {
		for(j = i+1; j < PDH_acnt; j++) {
			dist = p2p_distance(i,j);
			h_pos = (int) (dist / PDH_res);
			histogram[h_pos].d_cnt++;
		} 
	}
	return 0;
}


__device__ double d_p2p_distance(atom *d_atom_list, int ind1, int ind2) {

	double x1 = d_atom_list[ind1].x_pos;
	double x2 = d_atom_list[ind2].x_pos;
	double y1 = d_atom_list[ind1].y_pos;
	double y2 = d_atom_list[ind2].y_pos;
	double z1 = d_atom_list[ind1].z_pos;
	double z2 = d_atom_list[ind2].z_pos;

	return sqrt((x1 - x2)*(x1-x2) + (y1 - y2)*(y1 - y2) + (z1 - z2)*(z1 - z2));
}


/* Part A: one thread per point, counts go straight to the global histogram */
__global__ void PDH_kernel_global(atom *d_atom_list, bucket *d_histogram, int n, double w) {
	int i = blockDim.x*blockIdx.x + threadIdx.x;
	int j, h_pos;
	double dist;

	if(i < n) {
		for(j = i+1; j < n; j++) {
			dist = d_p2p_distance(d_atom_list, i, j);
			h_pos = (int) (dist / w);
			atomicAdd((unsigned long long *)&(d_histogram[h_pos].d_cnt), (unsigned long long)1);
		}
	}
}


/* Part B: counts go to a block-local shared histogram, then merge into global */
__global__ void PDH_kernel_shared(atom *d_atom_list, bucket *d_histogram, int n, double w, int n_buckets) {
	extern __shared__ unsigned long long s_histogram[];
	int i = blockDim.x*blockIdx.x + threadIdx.x;
	int b, j, h_pos;
	double dist;

	for(b = threadIdx.x; b < n_buckets; b += blockDim.x)
		s_histogram[b] = 0;
	__syncthreads();

	if(i < n) {
		for(j = i+1; j < n; j++) {
			dist = d_p2p_distance(d_atom_list, i, j);
			h_pos = (int) (dist / w);
			atomicAdd(&(s_histogram[h_pos]), (unsigned long long)1);
		}
	}
	__syncthreads();

	for(b = threadIdx.x; b < n_buckets; b += blockDim.x)
		atomicAdd((unsigned long long *)&(d_histogram[b].d_cnt), s_histogram[b]);
}


void check_cuda_error(const char *msg) {
	cudaError_t err = cudaGetLastError();
	if(err != cudaSuccess) {
		printf("Error in %s: %s\n", msg, cudaGetErrorString(err));
		exit(1);
	}
}

/* 
	set a checkpoint and show the (natural) running time in seconds 
*/
double report_running_time(const char *version) {
	long sec_diff, usec_diff;
	gettimeofday(&endTime, &Idunno);
	sec_diff = endTime.tv_sec - startTime.tv_sec;
	usec_diff= endTime.tv_usec-startTime.tv_usec;
	if(usec_diff < 0) {
		sec_diff --;
		usec_diff += 1000000;
	}
	printf("Running time for %s: %ld.%06ld\n", version, sec_diff, usec_diff);
	return (double)(sec_diff*1.0 + usec_diff/1000000.0);
}


/* 
	print the counts in all buckets of the histogram 
*/
void output_histogram(bucket *hist){
	int i; 
	long long total_cnt = 0;
	for(i=0; i< num_buckets; i++) {
		if(i%5 == 0) /* we print 5 buckets in a row */
			printf("\n%02d: ", i);
		printf("%15lld ", hist[i].d_cnt);
		total_cnt += hist[i].d_cnt;
	  	/* we also want to make sure the total distance count is correct */
		if(i == num_buckets - 1)	
			printf("\n T:%lld \n", total_cnt);
		else printf("| ");
	}
}


/* Compare CPU and GPU histograms and print the difference histogram */
bool compare_histograms(bucket *cpu_hist, bucket *gpu_hist) {
	bool match = true;

	printf("\nDifference between CPU and GPU histograms:\n");

	for (int i = 0; i < num_buckets; i++) {
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


/* run one GPU version, print its time, histogram and difference, return the kernel time */
double PDH_gpu(int use_shared) {
	double kernel_time;
	bool correct;

	cudaMemset(d_histogram, 0, sizeof(bucket)*num_buckets);
	gettimeofday(&startTime, &Idunno);
	if(use_shared)
		PDH_kernel_shared <<< num_blocks, block_size, sizeof(unsigned long long)*num_buckets >>> (d_atom_list, d_histogram, PDH_acnt, PDH_res, num_buckets);
	else
		PDH_kernel_global <<< num_blocks, block_size >>> (d_atom_list, d_histogram, PDH_acnt, PDH_res);
	cudaDeviceSynchronize();
	printf("\n");
	kernel_time = report_running_time(use_shared ? "GPU shared memory kernel" : "GPU global memory kernel");
	check_cuda_error("kernel");

	cudaMemcpy(gpu_histogram, d_histogram, sizeof(bucket)*num_buckets, cudaMemcpyDeviceToHost);
	output_histogram(gpu_histogram);
	correct = compare_histograms(histogram, gpu_histogram);
	printf("Correctness: %s\n", correct ? "PASS" : "FAIL");
	return kernel_time;
}


int main(int argc, char **argv)
{
	int i;
	double global_time, shared_time;

	PDH_acnt = atoi(argv[1]);
	PDH_res	 = atof(argv[2]);
	if(argc > 3)
		block_size = atoi(argv[3]);
//printf("args are %d and %f\n", PDH_acnt, PDH_res);

	num_buckets = (int)(BOX_SIZE * 1.732 / PDH_res) + 1;
	histogram = (bucket *)calloc(num_buckets, sizeof(bucket));
	gpu_histogram = (bucket *)malloc(sizeof(bucket)*num_buckets);

	atom_list = (atom *)malloc(sizeof(atom)*PDH_acnt);

	
	srand(1);
	/* generate data following a uniform distribution */
	for(i = 0;  i < PDH_acnt; i++) {
		atom_list[i].x_pos = ((double)(rand()) / RAND_MAX) * BOX_SIZE;
		atom_list[i].y_pos = ((double)(rand()) / RAND_MAX) * BOX_SIZE;
		atom_list[i].z_pos = ((double)(rand()) / RAND_MAX) * BOX_SIZE;
	}
	/* start counting time */
	gettimeofday(&startTime, &Idunno);
	
	/* call CPU single thread version to compute the histogram */
	PDH_baseline();
	
	/* check the total running time */ 
	report_running_time("CPU version");
	
	/* print out the histogram */
	output_histogram(histogram);

	cudaMalloc((void**) &d_atom_list, sizeof(atom)*PDH_acnt);
	cudaMalloc((void**) &d_histogram, sizeof(bucket)*num_buckets);
	cudaMemcpy(d_atom_list, atom_list, sizeof(atom)*PDH_acnt, cudaMemcpyHostToDevice);
	check_cuda_error("GPU memory setup");
	num_blocks = (PDH_acnt + block_size - 1)/block_size;

	global_time = PDH_gpu(0);
	shared_time = PDH_gpu(1);

	printf("\nShared memory kernel speedup over global memory kernel: %.2fx\n", global_time / shared_time);

	cudaFree(d_atom_list);
	cudaFree(d_histogram);
	free(histogram);
	free(gpu_histogram);
	free(atom_list);

	return 0;
}
