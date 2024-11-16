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
use JSON::PP;
use Data::Dumper;

# Paths and settings
my $source = "/home/jsp1/borophene/initial";
my $DLPjson = "borophene_pb_rcut6_smp5.json";
my $out_dir = "borophene_pb_rcut6_smp5"; # Directory to store output
my $temp_json = "/home/jsp1/final_dpa_training/multi-task_wen/train_dpa1.json";

`rm -rf $out_dir`;
`mkdir -p $out_dir`;

# Read and decode JSON
my $json;
{
    local $/ = undef;
    open my $fh, '<', "$temp_json" or die "No template.json in scripts path $temp_json\n";
    $json = <$fh>;
    close $fh;
}

my $json_parser = JSON::PP->new->allow_nonref->canonical(1);
my $decoded = $json_parser->decode($json);

# Define your new models
my @new_models = ("model1", "model2", "model3"); # Customize as needed

# Step 1: Modify "data_dict"
$decoded->{"training"}{"data_dict"} = {}; # Clear existing data_dict
foreach my $model (@new_models) {
    $decoded->{"training"}{"data_dict"}{$model} = {
        "training_data" => {
            "systems"    => [],
            "batch_size" => 1,
            "_comment"   => "Added for new model"
        }
    };
}

# Step 2: Modify "model_prob"
$decoded->{"training"}{"model_prob"} = {}; # Clear existing model_prob
foreach my $model (@new_models) {
    $decoded->{"training"}{"model_prob"}{$model} = 1.0; # Assign equal probability (adjust as needed)
}

# Step 3: Modify "model_dict"
$decoded->{"model"}{"model_dict"} = {}; # Clear existing model_dict
foreach my $model (@new_models) {
    $decoded->{"model"}{"model_dict"}{$model} = {
        "type_map"    => "type_map_all",
        "descriptor"  => "dpa2_descriptor",
        "fitting_net" => {
            "neuron"               => [240, 240, 240],
            "activation_function"  => "tanh",
            "resnet_dt"            => JSON::PP::true,
            "seed"                 => 1,
            "_comment"             => "New fitting network"
        }
    };
}

# Step 4: Optional: Update comments or metadata
$decoded->{"_comment"} = "Modified for new models";

# Step 5: Save the modified JSON
my $updated_json = $json_parser->pretty->encode($decoded);
open my $out_fh, '>', "$out_dir/modified_$DLPjson" or die "Cannot write to output file in $out_dir\n";
print $out_fh $updated_json;
close $out_fh;

print "Updated JSON saved to $out_dir/modified_$DLPjson\n";

# Debugging: Print modified JSON structure
print Dumper($decoded);
