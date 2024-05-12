access-cpu: Uses pthreads to demonstrate how chunked memory access is faster
than striped access on the CPU. This is because threads are scheduled for
a period of time on the CPU, where each one is scheduled after the next. This
means cache usage is maximized in a given thread when memory is accessed in
a sequential pattern (chunked). Striped access is slow because it only allows
a given thread to access a fraction (1 / NTHREADS) of each cache line.

access-gpu: Uses CUDA to demonstrate how striped memory access is faster
than chunked access on the GPU. This is because GPU threads execute together
on a per-block basis. Since they share the same cache, an interleaved (striped) 
memory access pattern will allow all threads in a block to read from the same
cache line.

General Findings:

pthread speedup 1 -> 10 (bad access):	1.15x
pthread speedup 1 -> 10 (good access):	4-5x

cuda speedup <<<1,1>>> -> <<<8,64>>> (bad access):	9x
cuda speedup <<<1,1>>> -> <<<8,64>>> (good access):	256x
