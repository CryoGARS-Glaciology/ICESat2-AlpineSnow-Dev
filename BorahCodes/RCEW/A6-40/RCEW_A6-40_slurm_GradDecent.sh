#!/bin/bash
#SBATCH -J MATLAB          # job name
#SBATCH -o log_matlab.o%j  # output and error file name (%j expands to jobID)
#SBATCH -n 1               # Run one process
#SBATCH --cpus-per-task=48 # with a full 48 cores
#SBATCH -p bsudfq          # queue (partition)
#SBATCH -t 3-00:00:00      # run time (d-hh:mm:ss)

ulimit -v unlimited
ulimit -s unlimited
ulimit -u 10000

module load matlab

# Execute the program:
# Replace test.m with the name of your matlab script.
# It should be in the same folder that you submit this from.

matlab -nodisplay -nosplash -nodesktop -r "run ./RCEW_A640_GradDecent.m ; quit"
