#ifndef ACCESS_H
#define ACCESS_H

#include <sys/time.h>
#include <stdio.h>

// entries in array
#define ARR_SIZE 100000000
// boolean, 1 if printing array
#define PRINTING 0
// compute elapsed time between 2 timevals
#define TIME(t1, t2) ((t2).tv_sec-(t1).tv_sec)+(((t2).tv_usec-(t1).tv_usec)/1e6)

// print array
void printArr(int *arr){
	for(int i = 0; i < ARR_SIZE-1; i++){
		printf("%d ", arr[i]);
	}
	printf("%d\n", arr[ARR_SIZE-1]);
}

#endif
