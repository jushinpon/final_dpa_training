=b
make lmp input files for all strucutres in labelled folders.
You need to use this script in the dir with all dpgen collections (in all_cfgs folder)
perl ../tool_scripts/cfg2lmpinput.pl 
=cut
use warnings;
use strict;
use JSON::PP;
use Data::Dumper;
use List::Util qw(min max);
use Cwd;
use POSIX;
use Parallel::ForkManager;
use List::Util qw/shuffle/;

my %sbatch_para = (
            nodes => 1,#how many nodes for your lmp job
            #nodes => 1,#how many nodes for your lmp job
            threads => 1,,#modify it to 2, 4 if oom problem appears
            #cpus_per_task => 1,
            partition => "All",#which partition you want to use
            #partition => "All",#which partition you want to use
            basename => "borophene_pb_rcut6_smp5", #for alloy.json
            #basename => "alloy_r9", #for alloy.json
            #basename => "oc2m_r9", #for alloy.json
            out_dir => "borophene_pb_rcut6_smp5"
            #finetune_file => "/opt/dpa_pretrained/oc2m_r9.pb"        
            #out_dir => "OC2M_dpa1_pb_rcut9"        
            );

my $currentPath = getcwd();# dir for all scripts

#my $forkNo = 1;#although we don't have so many cores, only for submitting jobs into slurm
#my $pm = Parallel::ForkManager->new("$forkNo");

my $basename = $sbatch_para{basename};
#my @all_files = `find $currentPath/$filefold -maxdepth 2 -mindepth 2 -type f -name "*.in" -exec readlink -f {} \\;|sort`;
#map { s/^\s+|\s+$//g; } @all_files;

#my $jobNo = 1;

#for my $i (@all_files){
#    print "Job Number $jobNo: $i\n";
#    my $basename = `basename $i`;
#    my $dirname = `dirname $i`;
#    $basename =~ s/\.in//g; 
#    chomp ($basename,$dirname);
#    `rm -f $dirname/$basename.sh`;
#    $jobNo++;
my $here_doc =<<"END_MESSAGE";
#!/bin/sh
#SBATCH --output=$basename.dpout
#SBATCH --job-name=dptrain_$basename
#SBATCH --nodes=$sbatch_para{nodes}
##SBATCH --cpus-per-task=2
##SBATCH --cpus-per-task=$sbatch_para{threads}
#SBATCH --partition=$sbatch_para{partition}
##SBATCH --ntasks-per-node=12
##SBATCH --nodelist=master

hostname

#source /opt/anaconda3/bin/activate deepmd-cpu-v3
#export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
#export PATH=/opt/deepmd-cpu-v3/bin:\$PATH

source /opt/anaconda3/bin/activate deepmd-cpu
export LD_LIBRARY_PATH=/opt/deepmd-cpu/lib:/opt/deepmd-cpu/lib/deepmd_lmp:\$LD_LIBRARY_PATH
export PATH=/opt/deepmd-cpu/bin:\$PATH


node=$sbatch_para{nodes}
threads=\$(nproc)
processors=\$(nproc)
np=\$((\$node*\$processors/\$threads))

#The following for deepmd v3
#export DP_INTRA_OP_PARALLELISM_THREADS=\$processors
#export DP_INTER_OP_PARALLELISM_THREADS=\$np

export DP_INTRA_OP_PARALLELISM_THREADS=\$np
export DP_INTER_OP_PARALLELISM_THREADS=\$processors
export OMP_NUM_THREADS=\$processors
### sometimes works 
#export OMP_NUM_THREADS=1

## dpa1
dp train $basename.json --skip-neighbor-stat
dp freeze -o $basename.pb
dp compress -i $basename.pb -o $basename-compressed.pb -t $basename.json

## dpa1 finetune
#dp train $basename.json --skip-neighbor-stat --finetune $sbatch_para{finetune_file}
#dp freeze -o $basename.pb
#dp compress -i $basename.pb -o $basename-compressed.pb -t $basename.json

##dpa2 (no compress currently)
#dp --pt train $basename.json --skip-neighbor-stat
#dp --pt freeze -o $basename.pth

END_MESSAGE
    unlink "$sbatch_para{out_dir}/$basename.sh";
    print "$sbatch_para{out_dir}/$basename.sh\n";
    open(FH, "> $sbatch_para{out_dir}/$basename.sh") or die $!;
    print FH $here_doc;
    close(FH);        
#}#  

