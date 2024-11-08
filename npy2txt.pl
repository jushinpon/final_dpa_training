=b
conda activate deepmd-cpu-v3
/opt/deepmd-cpu-v3/bin
/opt/deepmd-cpu-v3/lib

export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:$LD_LIBRARY_PATH
export PATH=/opt/deepmd-cpu-v3/bin:$PATH
LAMMPS_PLUGIN_PATH=/opt/deepmd-cpu-v3/lib/deepmd_lmp
plugin load libdeepmd_lmp.so (in script)
=cut

use strict;
use warnings;
use Cwd;
use POSIX;
use List::Util 'shuffle';
#use lib '.';
#use elements;
my $npy_source = " /home/dp_data/Alloy";
#my $npy_source = " /home/dp_data/OC2M";
#my $npy_source = "/opt/OC2M";
my $currentPath = getcwd();
my @npy_files = `find $npy_source -type d -name "set*"`;
map { s/^\s+|\s+$//g; } @npy_files;

@npy_files = shuffle(@npy_files);
`rm -rf npy2txt`;
for my $n (0..2){#$#npy_files){
    `mkdir -p npy2txt/$n`;
    my @npy = `find $npy_source -type f -name "*.npy"`;
    map { s/^\s+|\s+$//g; } @npy;

    #print "$n: $npy_files[$n]\n";
    for my $i (@npy){
        #Construct the system command
        my $cmd = qq(python -c "import numpy as np; np.savetxt('$i', np.load('$i'))");
        #Execute the command
        system($cmd) == 0 or die "Failed to execute command: $!";
    }
}



