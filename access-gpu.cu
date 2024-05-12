#include <stdio.h>
#include <assert.h>
#include <sys/time.h>
#include "access.h"

// number of blocks (8 optimal)
#define GRID_DIM 8
// number of threads per block (64 optimal)
#define BLOCK_DIM 64
// total number of gpu threads
#define NTHREADS (GRID_DIM * BLOCK_DIM)
#define CUDA_CHECK() assert(cudaGetLastError() == cudaSuccess)

int arrChunked[ARR_SIZE];
int arrStriped[ARR_SIZE];

/*
	Unbalanced, old version of chunked:
	The final thread may execute half the work, in the worst case.
*/
__global__ void chunkedLazy(int *arr_d){
	int id = threadIdx.x + blockIdx.x * blockDim.x;
	int i = (ARR_SIZE / NTHREADS) * id;
	int iMax;
	if(id == NTHREADS - 1){
		iMax = ARR_SIZE;
	} else {
		iMax = i + (ARR_SIZE / NTHREADS);
	}
	while(i < iMax){
		arr_d[i] = id;
		i++;
	}
}
/*
	Balanced version of chunked:
	(ARR_SIZE % NTHREADS) threads make ((ARR_SIZE / NTHREADS) + 1) access,
	while the rest make (ARR_SIZE / NTHREADS) accesses.
*/
__global__ void chunked(int *arr_d){
	int id = threadIdx.x + blockIdx.x * blockDim.x;
	int i; // start
	int iMax; // end (+ 1)
	if(id < (ARR_SIZE % NTHREADS)){ // do 1 extra
		i = ((ARR_SIZE / NTHREADS) + 1) * id;
		iMax = i + ((ARR_SIZE / NTHREADS) + 1);
	} else { // don't do extra
		i = ((ARR_SIZE / NTHREADS) * id) + (ARR_SIZE % NTHREADS);
		iMax = i + (ARR_SIZE / NTHREADS);
	}
	while(i < iMax){
		arr_d[i] = id;
		i++;
	}
}

__global__ void striped(int *arr_d){
	int id = threadIdx.x + blockIdx.x * blockDim.x;
	int i = id;
	while(i < ARR_SIZE){
		arr_d[i] = id;
		i += NTHREADS;
	}
}

int main(){
	printf("Running access-gpu...\n");
	printf("(GRID_DIM=%d) (BLOCK_DIM=%d) (ARR_SIZE=%d)\n", GRID_DIM, BLOCK_DIM, ARR_SIZE);
	printf("\n");

	struct timeval t_0, t_f;
	double tChunked, tStriped;
	
	int *arrChunked_d, *arrStriped_d;
	int size = ARR_SIZE * sizeof(int);
	cudaMalloc((void **) &arrChunked_d, size);
	CUDA_CHECK();
	cudaMalloc((void **) &arrStriped_d, size);
	CUDA_CHECK();
	
	// bad gpu access
	printf("Begin chunked access...\n");
	gettimeofday(&t_0, 0);
	chunked<<<GRID_DIM, BLOCK_DIM>>>(arrChunked_d);
	CUDA_CHECK();
	cudaDeviceSynchronize();
	CUDA_CHECK();
	gettimeofday(&t_f, 0);
	tChunked = TIME(t_0, t_f);
	printf("Chunked access complete in %lfs.\n", tChunked);
	printf("\n");

	// good gpu access
	printf("Begin striped access...\n");
	gettimeofday(&t_0, 0);
	striped<<<GRID_DIM, BLOCK_DIM>>>(arrStriped_d);
	CUDA_CHECK();
	cudaDeviceSynchronize();
	CUDA_CHECK();
	gettimeofday(&t_f, 0);
	tStriped = TIME(t_0, t_f);
	printf("Striped access complete in %lfs.\n", tStriped);
	printf("\n");
	
	printf("tChunked/tStriped: %lf\n", tChunked / tStriped);
	printf("\n");


	cudaMemcpy(arrChunked, arrChunked_d, size, cudaMemcpyDeviceToHost);
	CUDA_CHECK();
	cudaMemcpy(arrStriped, arrStriped_d, size, cudaMemcpyDeviceToHost);
	CUDA_CHECK();
	
	cudaFree(arrChunked_d);
	CUDA_CHECK();
	cudaFree(arrStriped_d);
	CUDA_CHECK();

	// arrays are now available on host
	
	if(PRINTING){
		printArr(arrChunked);
		printArr(arrStriped);
	}

	return 0;
}
