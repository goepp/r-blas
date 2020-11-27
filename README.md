
# Accelerating Linear Algebra Operations in R by changing the BLAS library

I read in many places that R can get way faster is you change the BLAS library it is linked to. Is it true?

**TL;DR: Yes**, changing your BLAS library can lead to massive speedups, especially for linear algebra operations. To see how to change your BLAS library, read along.

This repo is a tentative effort to understanding how to tune R to have good performances. If you have comments, critics, suggestions of benchmarks, or if you have results that you think may be useful, please leave a pull request!

## Choice of the numerical libraries
Most matrix computations in R and other programming languages are done by calling two numerical linear algebra libraries: BLAS (Basic Linear Algebra Subprograms) and LAPACK (Linear Algebra Package).

## BLAS
BLAS is actually a *specification* for the format used to call the common linear alebgra operations, so there exists different *implementations* of BLAS. Several implementations exist, some being optimized for better performance on a set specific CPUs. We name the main implementations hereafter (see details on their Wikipedia pages):

- Netlib BLAS: the official implementation
- GotoBLAS (and GotoBLAS2): open-source implementation (BSD Licence)
- OpenBLAS: open-source implementation based forked from GotoBLAS2 (BSD Licence)
- Intel MKL: developped by Intel for better performance on their CPUs (under the Intel Simplified Software License).
- ATLAS (Automatically Tuned Linear Algebra Software): open-source (BSD Licence)
- Accelerate: developped by Apple, optimized for MacOS and iOS.

## LAPACK
LAPACK is built on top of BLAS in the sense that it calls functions from BLAS. Hence, choosing a faster BLAS implementaion for your CPU may accelerate LAPACK as well.
Likewise BLAS, LAPACK comes under different implementations. Netlib LAPACK is the official LAPACK implementation, and Intel MKL and Accelerate both include a reimplementation of LAPACK.

Given that BLAS and LAPACK implementations often come bundled together, I will refer to both libraries under the name "BLAS".

## What is the best-fit BLAS for R

*A small word of caution*: for simplicity of use, stability, and reproducibility, R provides an internal BLAS and links its core functions, as well as the installed package, to it.
The [R installation and administration guide](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#BLAS) gives details on this.

### How to switching between BLASs

#### When compiling R
The [R installation and administration guide](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#BLAS) also documents one possible way to tell R which BLAS that R will use. It consists in [compiling R](https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Simple-compilation) with the flag `--with-blas` in the configuration file.
Details are given on how to install and link OpenBLAS, ATLAS, and Intel MKL.

#### System-wide switch on Linux
On Debian and Ubuntu, the command `update-alternatives` enables to set a symbolic link to default commands. It can be used to link the command `libblas.so.3` (used to call BLAS) between a set of alternative BLAS libraries.
This [blog post](https://brettklamer.com/diversions/statistical/faster-blas-in-r/) explains how.

#### Using a virtual environment
Conda enables to install R within a virtual environment. Within that virtual environment, we can choose a specific BLAS to be used by R.
The following commands install `conda` and creates the virtual environment (using the `conda_env.yaml` configuration file) with Intel MKL (written by [Héctor Climente-Gonzalez](@hclimente)).

```bash
# Download conda installer
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh 
# Execute conda installer
bash Miniconda3-latest-Linux-x86_64.sh

## add `export PATH="/home/<yourusername>/miniconda3/bin:$PATH"` to your .bashrc

conda config --add channels conda-forge
conda config --set channel_priority strict

# Create conda environment
conda env create --file conda_env_mkl.yaml
# Activate it
conda activate r-mkl
# Link the library `libblas` to the MKL library
echo "libblas[build=*mkl]" >> ${CONDA_PREFIX}/conda-meta/pinned

# Check:
R
sessionInfo()

# The output should include the line
# Matrix products: default
# BLAS/LAPACK: /home/<username>/miniconda3/envs/r-mkl/lib/libmkl_rt.dylib
```

## Is there a performance gain in switching BLAS?
A quick google search finds many blog posts which offer benchmarks between the aforementioned BLAS in R:

- [https://csantill.github.io/RPerformanceWBLAS/](https://csantill.github.io/RPerformanceWBLAS/)
- [https://www.r-bloggers.com/2017/11/why-is-r-slow-some-explanations-and-mklopenblas-setup-to-try-to-fix-this/](https://www.r-bloggers.com/2017/11/why-is-r-slow-some-explanations-and-mklopenblas-setup-to-try-to-fix-this/)
- This [post on the Intel website](https://software.intel.com/content/www/us/en/develop/articles/performance-comparison-of-openblas-and-intel-math-kernel-library-in-r.html) compares MKL to OpenBLAS for basic R operations, on an Intel® Xeon® processor E5-2697 v4.


Most of them seem to conclude that:

1. OpenBLAS and Intel MKL are the fastest
2. The BLAS shipped with R is slower
3. The difference between OpenBLAS and Intel MKL is not very significant

Here I will run some benchmarks using two scripts often used in this setting: `R-benchmark-25.R` and `revo-script` (available [here](https://github.com/pachamaltese/r-with-intel-mkl/tree/master/00-benchmark-scripts)).

### Results
I am using an Intel® Core™ i7-9750H CPU @2.60GHz CPU, running Ubuntu 20.04 with 31GB of memory.
I am running R 4.0 with the `Matrix` package in version 1.2-18.


#### R-benchmark-25.R
This script includes typical operations done in matrix calculations (e.g. cross-product), matrix functions (e.g. determinant, inverse, Cholesky decomposition, FFT, eigenvalues) , and programmation (e.g. creation of large matrices, computations on vectors).

Conda [includes](https://anaconda.org/conda-forge/libblas/files) MKL, OpenBLAS, BLIS, but not ATLAS.
By changing `mkl` to `openblas` or `blis` in the file `conda_env_mkl.yaml` we create 3 virtual environments, one with each BLAS library, and run `R-benchmark-25.R` within each.
 The results are compared with the default BLAS used by R:


| (Trimmed geom.) mean time (seconds) | R BLAS | BLIS | OpenBLAS | MKL  |
|-------------------------------------|--------|------|----------|------|
| Matrix calculation                  | 1.18   | 0.40 |  0.26    | **0.25** | 
| Matrix functions                    | 1.54   | 0.27 |  0.19    | **0.13** | 
| Programmation                       | **0.15**   | 0.16 |  0.16    | 0.17 | 
| Overall (trimmed) mean              | 0.65   | 0.26 |  0.20    | **0.19** | 
| Total time                          | 29.0   | 4.05 |  3.53    | **3.13** | 

MKL and OpenBLAS clearly have an edge. Let's see the other benchmark before concluding.

#### revo-script.R

This script performs some of the most typically used matrix calculations: crossproduct, Cholesky decomposition, singular value decomposition (SVD), principal component analysis (PCA), and linear discriminant analysis (LDA).
These operations are run on very large matrices ($10000$ x $2000$).

The elapsed times in seconds are:

| Matrix operation | R BLAS | BLIS  | OpenBLAS | MKL     |
|------------------|--------|-------|----------|---------|
| crossprod        | 134    |4.91   |1.67      |**1.45** | 
| Cholesky         | 19.3   |1.14   |**0.41**  |0.427    | 
| SVD              | 38.3   |5.01   |4.55      |**3.07** | 
| PCA              | 136    |12.3   |8.95      |**5.14** | 
| LDA              | 100    |20.8   |23.3      |**16.2** | 


**Conclusion**: on my system, I have the same performance ratios as the aforementioned blog posts: OpenBLAS and Intel MKL widely outperform the other libraries. **And the BLAS shipped with R and used by default is very slow compared to using the alternatives.**
I plan to systematically use MKL (or OpenBLAS) with R.

#### Do your own benchmarking
I included the files `conda_env_<BLAS_library>.yaml` for anyone to easily reproduce this benchmark.
Please tell me if you find the same results on your system (OS + CPU): I would add them here for reference.



### Issues with parallelized code
[This post](https://blog.revolutionanalytics.com/2015/10/edge-cases-in-using-the-intel-mkl-and-parallel-programming.html) warns that multithreaded libraries, like MKL, do not work well with parallelized code (using, for instance, `parallel::mclapply`). In that case, the author advises to set the number of threads to be used to 1, which, interestingly, does not alter the performance of Intel MKL very significantly.

## What about sparse matrices?
Applied mathematics are filled with problems whose solution is found by inverting a (large) matrix. And quite often, that matrix is sparse.
The package `Matrix` provides a rich set of classes for sparse matrices, and provides sparse implementations for many of the most useful matrix operations.
It namely implements crossproduct, Cholesky decomposition, and linear system solving for sparse matrices.
The goal of this section is to verify whether the choice of BLAS library has an impact the speed of these functions.


I consider square matrices with 8000, either non-symmetric or symmetric positive definite (spd).
The elapsed times (in seconds) are:

| Matrix operation             | R BLAS | BLIS |  OpenBLAS |  MKL |
|------------------------------|--------|-----|-----|-----|
|crossprod                     |6.35 |5.47|**5.26**|7.93|
|Cholesky                      |111 |88.8|**88.1**|156|
|Schur                         | 629|122.7|108|**91.177**|
|solve                         |337 |316|**279**| 395|
|solve (with spd matrix)       |73.2 |8.67|**3.82**|4.646|
|solve (after Cholesky decomp) |0.202 |**0.164**|**0.165**|0.235|

Conclusion: the choice of BLAS impact only on `Schur` and `solve` (with spd matrices).
Note: The `solve` using `Cholesky` decomposition calls a C library called CHOLMOD (see ?Matrix::Cholesky), so it is expected that its computing time does not depend on the BLAS library.
This line is here to remind that when inverting several sparse matrices with the *same* sparsity pattern, the choice of the BLAS library does not matter. Indeed, in this case, one can call `Cholesky` *once* (which is the computational bottleneck) and use that decompotion many times in the `Matrix::solve` function, which computes way faster than without reusing the Cholesky decomposition (see `?Matrix::`CHMfactor-class``.





## References

- Another post about BLAS benchmarking for R: [https://www.r-bloggers.com/2017/11/why-is-r-slow-some-explanations-and-mklopenblas-setup-to-try-to-fix-this/](https://www.r-bloggers.com/2017/11/why-is-r-slow-some-explanations-and-mklopenblas-setup-to-try-to-fix-this/)
