=b
Mg-Y
"rcut_smth":       2.00,
"rcut":            8.00,

water:
 "descriptor": {
      "type": "se_atten_v2",
      "sel": 120,
      "rcut_smth": 0.50,
      "rcut": 6.00,
ionic bond:

"rcut_smth": 0.5,
"rcut": 6.0,

ionic and partal covalent bonding:
"rcut_smth": 6.0,
"rcut": 7.0,

dpa2 for multi-task
"sel": 120,
"rcut_smth": 8.0,
"rcut": 9.0,      

=cut

use strict;
use warnings;
use Cwd;
use POSIX;
use JSON::PP;
use List::Util qw(max);

#use lib '.';
#use elements;
my $source = "/home/dp_data/Alloy";
my $DLPjson = "alloy_dpa2_pth_rcut9.json";
my $out_dir = "Alloy_dpa2_pth_rcut9";#remember to assign the corresponding rcut
`rm -rf $out_dir`;
`mkdir -p $out_dir`;
#my $temp_json = "trade-off.json";
my $temp_json = "dpa2_noVal.json";
my $trainstep = 2000000;# 2500000 for final training
my $descriptor_type = "dpa2";


my $rcut = 9.0000001;
my $rcut_smth = 8.00001;

#my $source = "/opt/OC2M";
my $currentPath = getcwd();

### if type_map.raw exists
my @ele_raw = `find $source -type f -name "type_map.raw"`;
map { s/^\s+|\s+$//g; } @ele_raw;

my @elements = `cat $ele_raw[0]`;
map { s/^\s+|\s+$//g; } @elements;

my $elements = join(" ",@elements);
chomp $elements;

unless (@elements){
    print "No type_map.raw, you need to provide the DLP elements\n";
    @elements = ("");
}

die "NO DLP elements assigned\n" unless (@elements);

my @DLP_elements = (@elements);#your DLP element sequence

my @train_dir = `find $source -type d -name "set*"`;
# Remove /set*** from each path
map { s|/set.*$||; } @train_dir;
map { s/^\s+|\s+$//g; } @train_dir;
die "No training dataset was found\n" unless(@train_dir);

print "\nThe following is for training:\n";
for my $n (@train_dir){
    print "$n\n";
}

my @all_train_dataset = @train_dir;
#@all_train_dataset = (@all_train_dataset,@all_val_dataset);

#@all_train_dataset = (@all_train_dataset,@all_val_dataset[0.. $#all_val_dataset - 1]);
#@all_val_dataset = ($all_val_dataset[-1]);
#die;
my %dptrain_setting; 
$dptrain_setting{type_map} = [@DLP_elements];# json template file
#$dptrain_setting{json_script} = "$currentPath/template.json";# json template file
#$dptrain_setting{json_outdir} = "$mainPath/dp_train";
#$dptrain_setting{working_dir} = "$mainPath/dp_train";
$dptrain_setting{trainstep} = $trainstep;#you may set a smaller train step for the first several dpgen processes
#$dptrain_setting{final_trainstep} = 200000;
#lr(t) = start_lr * decay_rate ^ ( t / decay_steps ),default decay_rate:0.95
$dptrain_setting{start_lr} = 0.001;
my $t1 = log(3.0e-08/$dptrain_setting{start_lr});
my $t2 = log(0.95)*$dptrain_setting{trainstep};
my $dcstep = floor($t2/$t1);
$dptrain_setting{decay_steps} = $dcstep;
$dptrain_setting{final_decay_steps} = 5000;
$dptrain_setting{disp_freq} = 1000;
$dptrain_setting{save_freq} = 1000;
my $temp =$dptrain_setting{start_lr} * 0.95**( $dptrain_setting{trainstep}/$dptrain_setting{decay_steps} );
$dptrain_setting{rcut} = $rcut;
$dptrain_setting{rcut_smth} = $rcut_smth;
#$dptrain_setting{nsel} = $nsel;
#$dptrain_setting{descriptor_type} = "$descriptor_type";
#$dptrain_setting{descriptor_type} = "se_a";
$dptrain_setting{save_ckpt} = "model.ckpt";
$dptrain_setting{save_ckpt4compress} = "model_compress.ckpt";
$dptrain_setting{disp_file} = "lcurve.out";
$dptrain_setting{disp_file4compress} = "lcurve_compress.out";


my $json;
{
    local $/ = undef;
    open my $fh, '<', "./$temp_json" or die "no template.json in scripts path $temp_json\n";
    $json = <$fh>;
    close $fh;
}

# Decode JSON with type preservation
my $json_parser = JSON::PP->new->allow_nonref->canonical(1);
my $decoded = $json_parser->decode($json);
#my $decoded = decode_json($json);

$decoded->{training}->{training_data}->{systems} = [@all_train_dataset];#clean it first
#find folders with /val
#$decoded->{training}->{validation_data}->{systems} = [@all_val_dataset];#clean it first
$decoded->{model}->{type_map} = [@DLP_elements];#clean it first
###

my $seed1 = ceil(12345 * rand());
chomp $seed1;
$decoded->{model}->{descriptor}->{seed} = $seed1;
my $seed2 = ceil(123456 * rand());
chomp $seed2;
$decoded->{model}->{fitting_net}->{seed} = $seed2;
my $seed3 = ceil(1234 * rand());
chomp $seed3;
$decoded->{training}->{seed} = $seed3;
$decoded->{training}->{numb_steps} = $trainstep;    
$decoded->{training}->{save_ckpt} = $dptrain_setting{save_ckpt};    
$decoded->{training}->{disp_file} = $dptrain_setting{disp_file};    
$decoded->{training}->{save_freq} = $dptrain_setting{save_freq};    
$decoded->{training}->{disp_freq} = $dptrain_setting{disp_freq};    
$decoded->{learning_rate}->{start_lr} = $dptrain_setting{start_lr};    
$decoded->{learning_rate}->{decay_steps} = $dptrain_setting{decay_steps};    
$decoded->{model}->{descriptor}->{repinit}->{rcut} = $dptrain_setting{rcut};    
$decoded->{model}->{descriptor}->{repinit}->{rcut_smth} = $dptrain_setting{rcut_smth};    
#$decoded->{model}->{descriptor}->{nsel} = $dptrain_setting{nsel};    
#$decoded->{model}->{descriptor}->{repinit}->{nsel} = $dptrain_setting{nsel};    
#$decoded->{model}->{descriptor}->{type} = $dptrain_setting{descriptor_type};    
`rm -f ./$DLPjson`;   
{
    local $| = 1;
    open my $fh, '>', "$out_dir/$DLPjson";
    print $fh JSON::PP->new->pretty->encode($decoded);#encode_json($decoded);
        close $fh;
}