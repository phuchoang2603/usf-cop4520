# COP4520 - Computing in Massively Parallel Systems

## Project 1: Spatial Distance Histogram Computation

**Deadline:** Wednesday, September 30, 2026 at 11:59 PM

## 1. Problem Statement

This project is about computing the spatial distance histogram (SDH) of a collection of 3D points. Given the coordinates of `N` particles (e.g., atoms, stars, or moving objects) and a user-defined distance `w`, compute the number of particle-to-particle distances falling into a series of buckets of width `w`:

`[0, w), [w, 2w), ..., [(l - 1)w, lw]`

The resulting SDH is an ordered list:

`H = (h0, h1, ..., h(l-1))`

where `hi` is the number of distances in bucket:

`[iw, (i + 1)w)`

The bucket width `w` is therefore a key parameter of the SDH.

## 2. Getting Started

Under `Files/Project1`, you can find the sample program `SDH_base.cu`, which serves as the starting point for this project. Although the provided implementation computes the SDH on the CPU, the `.cu` file can be compiled and executed in the CUDA environment on the GAIVI cluster.

Compile and run the starter code using:

```bash
/apps/GPU_course/runScript.sh SDH_base.cu 10000 500
```

The executable takes two arguments:

1. The total number of data points
2. The histogram bucket width `w`

We strongly suggest compiling and running the starter code before beginning your CUDA implementation.

## 3. Tasks to Perform

Write a CUDA program that implements the same SDH functionality as the provided CPU program. You will implement two GPU versions:

- A global-memory baseline
- A shared-memory optimization

### Part A - Global-Memory Histogram

Write a CUDA kernel that computes the distance counts in all SDH buckets by making each thread work on one input data point. After all points are processed, copy the resulting SDH back to a host data structure.

1. Transfer the input data array (the atom list shown in the sample code) to the GPU using CUDA functions.
2. Write a kernel to compute the distance from one point to the other points and update the histogram. Between any two points, only one distance should be counted.
3. Copy the final histogram from the GPU back to the host and output it in the same format used for the CPU result.
4. Compare the GPU histogram with the CPU histogram bucket by bucket and output a difference histogram with the same number of buckets.

### Part B - Shared-Memory Histogram Optimization

After completing Part A, implement a second CUDA kernel using a block-local histogram in shared memory.

Threads within a block should first accumulate histogram updates into the shared-memory histogram. After the block finishes its work, merge the block-local counts into the global histogram.

Initialize the shared histogram correctly and use the synchronization and atomic operations needed to prevent race conditions. This version must compute exactly the same SDH as the CPU implementation and Part A.

The following pseudocode illustrates the intended shared-memory approach:

```text
Shared-Memory Histogram Version

for each CUDA block:
    initialize the block-local histogram in shared memory
    each thread processes its assigned point
    for each required point pair:
        compute the distance
        determine the histogram bucket
        update the shared-memory histogram
    synchronize threads in the block
    merge the block-local shared histogram into the global histogram
```

### Performance Comparison

Provide the CPU running time and the kernel execution time for the global-memory GPU version and shared-memory
GPU version. Measure the two GPU kernel execution times consistently so the comparison is meaningful.

The shared-memory version is intended to reduce contention on the global histogram and should improve
performance. Compare the two GPU kernel execution times.

#### Required Program Output

Your output should contain: (1) the CPU histogram and CPU running time, (2) the global-memory GPU histogram, its
difference from the CPU histogram, and its kernel execution time, and (3) the shared-memory GPU histogram, its
difference from the CPU histogram, and its kernel execution time

After each GPU comparison, print `PASS` if all difference buckets are zero or `FAIL` otherwise.

The difference histogram must still be printed.

## 4. Environment

All projects will be tested on CUDA 11.4 on a machine in the GAIVI cluster.

If you prefer to work on your own computer, make sure your project can also be compiled and executed on the GPU of a GAIVI node.

## 5. Instructions to Submit Project

> Please carefully follow the submission guidelines.

Submit one `.cu` file containing your implementation. We suggest adding your code to the provided `SDH_base.cu`.

Rename the file as:

```text
proj1-xxx.cu
```

where `xxx` is your USF NetID. Use your NetID, not your U Number.

Submit the file only through the assignment link in Canvas. E-mail or any other form of submission will not be graded.

After submitting, download the submitted file from Canvas and open it to make sure no data-transmission problem occurred.

We strongly recommend submitting well before the deadline.

## 6. Rules for Grading

Project functionality will be graded using a set of test cases run against your submitted code.

- All programs that fail to compile will receive zero. We expect your submission to compile using the command shown above.
- If changes are required after the submission deadline to make the code work, they must be limited to three lines of code. This will incur a 30% penalty.
- The program should run for different numbers of CUDA blocks and different block sizes. Using tricks to make it run on one thread or only on the CPU will result in zero points.
- Both GPU implementations must produce results consistent with the provided CPU implementation.
- For Part B, the histogram will be small enough to fit in the available per-block shared memory.
- Provide the CPU running time and the kernel execution time for the global-memory GPU version and shared-memory GPU version. Measure the two GPU kernel execution times consistently so the comparison is meaningful.
- Your output should contain:
  1. The CPU histogram and CPU running time
  2. The global-memory GPU histogram, its difference from the CPU histogram, and its kernel execution time
  3. The shared-memory GPU histogram, its difference from the CPU histogram, and its kernel execution time
- Report the CPU running time and the kernel execution time for both GPU versions.
- The shared-memory version is intended to reduce contention on the global histogram and should improve performance. Compare the two GPU kernel execution times.
- Any submission that uses tricks to bypass the required global-memory or shared-memory GPU implementations, rather than genuinely implementing them, will receive a maximum project grade of 30%.

### Grading Breakdown

| Component                                                                       |  Points |
| ------------------------------------------------------------------------------- | ------: |
| Global-memory GPU histogram correctness                                         |      30 |
| Shared-memory GPU histogram correctness                                         |      30 |
| Correct pair handling and GPU execution                                         |      15 |
| Required CUDA techniques: atomic operations, shared memory, and synchronization |      15 |
| CPU/GPU kernel timing and short performance comparison                          |      10 |
| **Total**                                                                       | **100** |

Correctness will be checked using multiple input configurations, including different problem sizes, bucket widths, block sizes, and cases where the number of points is not evenly divisible by the block size.

### Atomic Updates to Histogram Buckets

In the CPU implementation, you may have used:

```c
histogram[h_pos].d_cnt++;
```

This produces incorrect results in CUDA when multiple threads modify the same memory location concurrently.

For the global GPU histogram, use an atomic update:

```c
atomicAdd(&(d_histogram[h_pos].d_cnt), (unsigned long long)1);
```

The same race-condition principle applies to the shared-memory histogram. If multiple threads can update the same shared-memory bucket concurrently, the update must also be protected appropriately.

## Important Notes for Project 1

### Comparing CPU and GPU Histograms

Use the following helper function to compare a GPU histogram against the CPU histogram. It prints the required bucket-by-bucket difference histogram and returns whether the two histograms match exactly.

```c
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
```

After copying a GPU result back to the host, use the return value to print a concise summary:

```c
bool correct = compare_histograms(cpu_hist, gpu_hist);
printf("Correctness: %s\n", correct ? "PASS" : "FAIL");
```

Run the comparison separately for the global-memory GPU result and the shared-memory GPU result.

A correct implementation should print zeros in every difference bucket and report `PASS`.

### Correctly Updating the Histogram Using `atomicAdd`

For the global histogram, use:

```c
atomicAdd(&(d_histogram[h_pos].d_cnt), (unsigned long long)1);
```

### Running Your CUDA Code

Once you have completed the implementation, run your CUDA program using:

```bash
/apps/GPU_course/runScript.sh mycode.cu 10000 500
```

Replace `mycode.cu` with your actual CUDA source file name.
