import os
import numpy as np
import shutil

# Directory containing .npy files
input_dir = '/home/dp_data/Alloy/train/alloy_dai/solid_solutions_mixed/dpgenrun/valid/22/set.000000'  # change this to your directory
output_dir = './txt_filesAlloy'  # output directory for .txt files

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Convert .npy files to .txt files
for filename in os.listdir(input_dir):
    if filename.endswith('.npy'):
        # Load .npy file
        npy_path = os.path.join(input_dir, filename)
        data = np.load(npy_path)
        
        # Create .txt file with the same prefix name
        txt_filename = os.path.splitext(filename)[0] + '.txt'
        txt_path = os.path.join(output_dir, txt_filename)
        
        # Save data to .txt file
        np.savetxt(txt_path, data, fmt='%s')
        print(f"Converted {npy_path} to {txt_path}")

# Copy all files from the parent directory of input_dir to output_dir
parent_dir = os.path.dirname(input_dir)

for filename in os.listdir(parent_dir):
    file_path = os.path.join(parent_dir, filename)
    
    # Ensure we are only copying files, not directories
    if os.path.isfile(file_path):
        shutil.copy(file_path, output_dir)
        print(f"Copied {file_path} to {output_dir}")
