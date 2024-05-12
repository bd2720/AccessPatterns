#include <stdio.h>
#include <sys/time.h>
#include <pthread.h>
#include <stdint.h>
#include "access.h"

#define NTHREADS 10

int arrayStriped[ARR_SIZE];
int arrayChunked[ARR_SIZE];

void *striped(void *arg){
	int id = (int)(uintptr_t)arg;
	int i = id;
	while(i < ARR_SIZE){
		arrayStriped[i] = id;
		i += NTHREADS;
	}
	return (void *) NULL;
}

/*
	Unbalanced, old version of chunked:
	The final thread may execute half the work, in the worst case.
*/
void *chunkedLazy(void *arg){
	int id = (int)(uintptr_t)arg;
	int i = (ARR_SIZE / NTHREADS) * id;
	int iMax;
	if(id == NTHREADS - 1){
		iMax = ARR_SIZE;
	} else {
		iMax = i + (ARR_SIZE / NTHREADS);
	}
	while(i < iMax){
		arrayChunked[i] = id;
		i++;
	}
	return (void *) NULL;
}
/*
	Balanced version of chunked:
	(ARR_SIZE % NTHREADS) threads make ((ARR_SIZE / NTHREADS) + 1) access,
	while the rest make (ARR_SIZE / NTHREADS) accesses.
*/
void *chunked(void *arg){
	int id = (int)(uintptr_t)arg;
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
		arrayChunked[i] = id;
		i++;
	}
	return (void *) NULL;
}

int main(){
	printf("Running access-cpu...\n");
	printf("(NTHREADS=%d) (ARR_SIZE=%d)\n", NTHREADS, ARR_SIZE);
	printf("\n");

	pthread_t tids[NTHREADS];
	int i;
		
	struct timeval t_0, t_f;
	double tStriped, tChunked;

	// bad cpu access
	printf("Begin striped access...\n");
	gettimeofday(&t_0, 0);
	for(i = 0; i < NTHREADS; i++){
		pthread_create(&tids[i], NULL, striped, (void *)(uintptr_t)i);
	}
	for(i = 0; i < NTHREADS; i++){
		pthread_join(tids[i], NULL);
	}
	gettimeofday(&t_f, 0);
	tStriped = TIME(t_0, t_f);
	printf("Striped access complete in %lfs.\n", tStriped);
	printf("\n");

	// good cpu access
	printf("Begin chunked access...\n");
	gettimeofday(&t_0, 0);
	for(i = 0; i < NTHREADS; i++){
		pthread_create(&tids[i], NULL, chunked, (void *)(uintptr_t)i);
	}
	for(i = 0; i < NTHREADS; i++){
		pthread_join(tids[i], NULL);
	}
	gettimeofday(&t_f, 0);
	tChunked = TIME(t_0, t_f);
	printf("Chunked access complete in %lfs.\n", tChunked);
	printf("\n");

	printf("tStriped/tChunked: %lf\n", tStriped / tChunked);
	printf("\n");

	if(PRINTING){
		printArr(arrayStriped);
		printArr(arrayChunked);
	}
		
	return 0;
}
