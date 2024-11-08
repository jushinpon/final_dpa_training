use strict;
use warnings;
use Cwd;
use POSIX;
use JSON::PP;
use List::Util qw(max);

#use lib '.';
#use elements;
my $source = "/opt/Alloy";
my $DLPjson = "alloy.json";
#my $temp_json = "trade-off.json";
my $temp_json = "alloy_torch_medium.json";
my $trainstep = 2000000;# 2500000 for final training
my $descriptor_type = "dpa2";

my $rcut = 5.5;
my $rcut_smth = 5.00001;

#my $source = "/opt/OC2M";
my $currentPath = getcwd();

my @ele_raw = `find $source -type f -name "type_map.raw"`;
map { s/^\s+|\s+$//g; } @ele_raw;

my @elements = `cat $ele_raw[0]`;
map { s/^\s+|\s+$//g; } @elements;

my $elements = join(" ",@elements);
chomp $elements;

my @DLP_elements = (@elements);#your DLP element sequence

#print "$elements\n";
#die;
my @train_dir = `find $source -mindepth 2 -type d -name "train"`;
map { s/^\s+|\s+$//g; } @train_dir;

my @val_dir = `find $source -type d -name "valid"`;
map { s/^\s+|\s+$//g; } @val_dir;

#print "\nThe following is for training:\n";
#for my $n (@train_dir){
#    print "$n\n";
#}
#print "\nThe following is for validation:\n";
#for my $n (@val_dir){
#    print "$n\n";
#}
### You need to check the above first!!!!!

#get all training data set
my @all_train_dataset;
for my $n (@train_dir){
    my @temp = `find $n -mindepth 1 -maxdepth 1 -type d`;
    map { s/^\s+|\s+$//g; } @temp;
    for my $i (@temp){
        push @all_train_dataset,$i;
    }
#    my $temp = join("\n",@temp);
}
my $all_train_dataset = join("\n",@all_train_dataset);
chomp $all_train_dataset;

#get all validation data set
my @all_val_dataset;
for my $n (@val_dir){
    my @temp = `find $n -mindepth 1 -maxdepth 1 -type d`;
    map { s/^\s+|\s+$//g; } @temp;
    for my $i (@temp){
        push @all_val_dataset,$i;
    }
    #my $temp = join("\n",@temp);
    #push @all_val_dataset,$temp;
}
my $all_val_dataset = join("\n",@all_val_dataset);
chomp $all_val_dataset;
#print "$all_val_dataset\n";

#find nsel
my @allnpy = (@all_train_dataset,@all_val_dataset);
my $rlist = $rcut;
my $ele = join (" ",@elements);
my $eleno = @elements - 1;
#my $eleno = @elements;
chomp $ele;
my $max = 1;
#for my $n (@allnpy){
#    #for my $e (@elements){
#        print "$n\n";
#        #dp --tf neighbor-stat -s data -r 6.0 -t O H
#        my $temp = `dp --tf neighbor-stat -s $n -r $rlist -t $ele 2>&1| grep -A 5 max_nbor_size:`;
#       # map { s/^\s+|\s+$//g; } @temp;
#        
#        $temp =~ s/^\s+|\s+$//g;
#        print "*********************";#\$temp: @temp\n";
#       # if ($capture && /\[([^\]]+)\]/) {
#        $temp =~  /((?:\d+\s+){$eleno}\d+)/;
#        #print "\$1:$1";
#        my @numbers = split ' ', $1;  # Split numbers by whitespace
#        die "element numbers are not identical!\n" unless(@numbers == @elements);
#        $max = max($max,@numbers);
#        print "\$max:$max\n";
#        #for (0 .. $#numbers){
#        #    print "$_: $numbers[$_]\n";
##
#        #}
#        ##push @max_nbor_size, @numbers;
#       ##  }
#        #print "+++++++++++++++++++++++\n";
#        #die;
#        #last;
#    #}
##die;
#}
# print "******Final \$max: $max\n";
#my $nsel = $max + 5;

@all_train_dataset = (@all_train_dataset,@all_val_dataset[0.. $#all_val_dataset - 1]);
@all_val_dataset = ($all_val_dataset[-1]);
#die;
my %dptrain_setting; 
$dptrain_setting{type_map} = [@DLP_elements];# json template file
#$dptrain_setting{json_script} = "$currentPath/template.json";# json template file
#$dptrain_setting{json_outdir} = "$mainPath/dp_train";
#$dptrain_setting{working_dir} = "$mainPath/dp_train";
$dptrain_setting{trainstep} = $trainstep;#you may set a smaller train step for the first several dpgen processes
#$dptrain_setting{final_trainstep} = 200000;
#lr(t) = start_lr * decay_rate ^ ( t / decay_steps ),default decay_rate:0.95
$dptrain_setting{start_lr} = 0.002;
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
$decoded->{training}->{validation_data}->{systems} = [@all_val_dataset];#clean it first
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
    open my $fh, '>', "./$DLPjson";
    print $fh JSON::PP->new->pretty->encode($decoded);#encode_json($decoded);
        close $fh;
}