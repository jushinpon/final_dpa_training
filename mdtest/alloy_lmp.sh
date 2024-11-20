#!/bin/sh
#SBATCH --output=Au.lmpout
#SBATCH --job-name=dptrain_alloy
#SBATCH --nodes=1
##SBATCH --cpus-per-task=2
##SBATCH --cpus-per-task=4
#SBATCH --partition=All
##SBATCH --ntasks-per-node=12

hostname
if [ -f /opt/anaconda3/bin/activate ]; then
    
    source /opt/anaconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:\$PATH

elif [ -f /opt/miniconda3/bin/activate ]; then
    source /opt/miniconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:\$PATH
else
    echo "Error: Neither /opt/anaconda3/bin/activate nor /opt/miniconda3/bin/activate found."
    exit 1  # Exit the script if neither exists
fi

node=1
threads=$(nproc)
processors=$(nproc)
np=$(($node*$processors/$threads))

export OMP_NUM_THREADS=$processors
export TF_INTRA_OP_PARALLELISM_THREADS=$processors
#export TF_INTER_OP_PARALLELISM_THREADS=6


#export OMP_NUM_THREADS=$threads
#export OMP_NUM_THREADS=12
#export TF_INTRA_OP_PARALLELISM_THREADS=$np
#export TF_INTER_OP_PARALLELISM_THREADS=$threads
#The following are used only for intel MKL (not workable for AMD)
#export KMP_AFFINITY=granularity=fine,compact,1,0
#export KMP_BLOCKTIME=0
#export KMP_SETTINGS=TRUE

#lmp -in Au.in
mpirun -n $np lmp -in Au.in
#dp --pt train alloy.json --skip-neighbor-stat
#dp --pt freeze -o alloy.pth
#torchrun --nproc_per_node=$np --no-python dp --pt train alloy.json --skip-neighbor-stat


