# Code extracted from lecture slides

These files transcribe the code examples, API signatures, pseudocode, and indexing
expressions in the nine PDFs in `../lectures/`. Chapter 1 contains no code examples.
Folders follow the source lectures; filenames and source comments identify **1-based
PDF pages**, which can differ from the printed slide numbers. Identical repeated
examples within a lecture are consolidated and list all their source pages.

The extraction restores indentation, joins PDF-split identifiers, normalizes the
Unicode dash in the page 21 block-count formula to `-`, and removes slide bullets,
line numbers, highlights and explanatory labels. Algorithms, identifiers, placeholder
`...` expressions, and original slide errors are preserved. No host drivers, includes,
missing function wrappers, macro values or missing braces have been invented.

These are study excerpts, not a buildable application. `.cu` identifies CUDA material,
including partial bodies and pseudocode. CPU excerpts use `.c` or `.cpp`. Some examples
lack boundary checks intentionally; others require `TILE_DIM`, `TILE_WIDTH`,
`BLOCK_SIZE` or `BLUR_SIZE` and surrounding declarations.

Known source issues retained:

- Reduction page 13 uses `partialSum[blockDim+t]` without `.x`.
- Tiled multiplication pages 5–6 use `TILE*WIDTH`; pages 8–10 use `Int`, an
  undeclared `n` in the loop bound, `t` instead of `p` in the N load, and
  `__synchthreads()` for the second barrier.
- Tiled multiplication page 25 and warp divergence page 13 mix `t` and `p`.
- Tiled multiplication page 26 opens an output-boundary `if` without supplying
  its matching closing brace. The excerpt is preserved separately from page 25.
- Chapter 5 page 26 omits the dynamic shared array's element type and the launch
  semicolon. Warp divergence page 9 uses capitalized `If`.
- API signatures, index expressions and pseudocode may omit semicolons or use
  placeholders exactly as shown.

Attribution: Chapters 1–5 are © 2022 Elsevier, Wen-mei Hwu, David Kirk and Izzat
El Hajj, *Programming Massively Parallel Processors: A Hands-on Approach*.
The GPU Teaching Kit slides credit NVIDIA and the University of Illinois and state
a Creative Commons Attribution-NonCommercial 4.0 license:
https://creativecommons.org/licenses/by-nc/4.0/.

## Source index

### Chapter 02 - Heterogeneous Data Parallel Computing.pdf

- [page_03_vector_add_cpu.c](chapter_02/page_03_vector_add_cpu.c) — PDF page(s) 3.
- [page_06_memory_allocation_api.cu](chapter_02/page_06_memory_allocation_api.cu) — PDF page(s) 6.
- [page_07_memory_copy_api.cu](chapter_02/page_07_memory_copy_api.cu) — PDF page(s) 7.
- [page_08_vector_add_memory_management.cu](chapter_02/page_08_vector_add_memory_management.cu) — PDF page(s) 8.
- [pages_12_19_vector_add_launch.cu](chapter_02/pages_12_19_vector_add_launch.cu) — PDF page(s) 12, 19.
- [page_18_vector_add_kernel.cu](chapter_02/page_18_vector_add_kernel.cu) — PDF page(s) 18.
- [page_21_vector_add_boundary_checks.cu](chapter_02/page_21_vector_add_boundary_checks.cu) — PDF page(s) 21.
- [page_24_host_device_functions.cu](chapter_02/page_24_host_device_functions.cu) — PDF page(s) 24.
- [page_26_device_synchronize_api.cu](chapter_02/page_26_device_synchronize_api.cu) — PDF page(s) 26.
- [page_27_error_checking.cu](chapter_02/page_27_error_checking.cu) — PDF page(s) 27.

### Chapter 03 - Multidimensional Grids and Data.pdf

- [page_04_grayscale_launch.cu](chapter_03/page_04_grayscale_launch.cu) — PDF page(s) 4.
- [page_10_grayscale_indexing.cu](chapter_03/page_10_grayscale_indexing.cu) — PDF page(s) 10.
- [page_13_grayscale_kernel.cu](chapter_03/page_13_grayscale_kernel.cu) — PDF page(s) 13.
- [page_14_grayscale_boundary_checks.cu](chapter_03/page_14_grayscale_boundary_checks.cu) — PDF page(s) 14.
- [page_17_blur_kernel.cu](chapter_03/page_17_blur_kernel.cu) — PDF page(s) 17.
- [page_19_blur_boundary_checks.cu](chapter_03/page_19_blur_boundary_checks.cu) — PDF page(s) 19.
- [page_22_matrix_multiplication.cu](chapter_03/page_22_matrix_multiplication.cu) — PDF page(s) 22.

### Chapter 04 - Compute Architecture and Scheduling.pdf

- [page_13_branch_divergence.cu](chapter_04/page_13_branch_divergence.cu) — PDF page(s) 13.
- [page_14_loop_divergence.cu](chapter_04/page_14_loop_divergence.cu) — PDF page(s) 14.
- [page_21_device_properties.cu](chapter_04/page_21_device_properties.cu) — PDF page(s) 21.

### Chapter 05 - Memory Architecture and Data Locality.pdf

- [page_04_vector_add_statement.cu](chapter_05/page_04_vector_add_statement.cu) — PDF page(s) 4.
- [page_05_matrix_inner_product.cu](chapter_05/page_05_matrix_inner_product.cu) — PDF page(s) 5.
- [page_10_memory_declarations.cu](chapter_05/page_10_memory_declarations.cu) — PDF page(s) 10.
- [page_18_tiled_matrix_multiplication.cu](chapter_05/page_18_tiled_matrix_multiplication.cu) — PDF page(s) 18.
- [page_24_cpu_tiling.cpp](chapter_05/page_24_cpu_tiling.cpp) — PDF page(s) 24.
- [page_26_dynamic_shared_memory.cu](chapter_05/page_26_dynamic_shared_memory.cu) — PDF page(s) 26.

### Lecture-Reduction.pdf

- [page_13_load_shared_memory.cu](reduction/page_13_load_shared_memory.cu) — PDF page(s) 13.
- [page_14_naive_reduction.cu](reduction/page_14_naive_reduction.cu) — PDF page(s) 14.
- [page_20_better_reduction.cu](reduction/page_20_better_reduction.cu) — PDF page(s) 20.

### Lecture-memory-coalescing.pdf

- [page_06_coalesced_access_pattern.cu](memory_coalescing/page_06_coalesced_access_pattern.cu) — PDF page(s) 6.
- [page_08_matrix_access_patterns.cu](memory_coalescing/page_08_matrix_access_patterns.cu) — PDF page(s) 8.
- [page_11_tile_zero_indexing.cu](memory_coalescing/page_11_tile_zero_indexing.cu) — PDF page(s) 11.

### Lecture-tiled-matrix-multiplication.pdf

- [pages_03_04_tile_zero_indexing.cu](tiled_matrix_multiplication/pages_03_04_tile_zero_indexing.cu) — PDF page(s) 3, 4.
- [pages_05_06_tile_one_indexing.cu](tiled_matrix_multiplication/pages_05_06_tile_one_indexing.cu) — PDF page(s) 5, 6.
- [page_07_linear_indexing.cu](tiled_matrix_multiplication/page_07_linear_indexing.cu) — PDF page(s) 7.
- [pages_08_09_10_tiled_kernel.cu](tiled_matrix_multiplication/pages_08_09_10_tiled_kernel.cu) — PDF page(s) 8, 9, 10.
- [page_23_m_tile_boundary.cu](tiled_matrix_multiplication/page_23_m_tile_boundary.cu) — PDF page(s) 23.
- [page_24_n_tile_boundary.cu](tiled_matrix_multiplication/page_24_n_tile_boundary.cu) — PDF page(s) 24.
- [page_25_boundary_checked_loads.cu](tiled_matrix_multiplication/page_25_boundary_checked_loads.cu) — PDF page(s) 25.
- [page_26_boundary_checked_inner_product.cu](tiled_matrix_multiplication/page_26_boundary_checked_inner_product.cu) — PDF page(s) 26.

### Lecture-warps-divergence.pdf

- [page_09_branch_examples.cu](warps_divergence/page_09_branch_examples.cu) — PDF page(s) 9.
- [page_10_vector_add_kernel.cu](warps_divergence/page_10_vector_add_kernel.cu) — PDF page(s) 10.
- [page_13_tile_loading_boundary_checks.cu](warps_divergence/page_13_tile_loading_boundary_checks.cu) — PDF page(s) 13.
