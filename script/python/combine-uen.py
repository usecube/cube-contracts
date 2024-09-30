import json
import os

# Define the input and output paths
input_dir = '../../data/json/'
output_file = '../../data/json/combined_uen.json'

# Initialize an empty list to store all the data
combined_data = []

# Process files from A to Z and others
for letter in list('ABCDEFGHIJKLMNOPQRSTUVWXYZ') + ['others']:
    input_file = f'{input_dir}{letter}.json'
    if os.path.exists(input_file):
        with open(input_file, 'r') as f:
            data = json.load(f)
            combined_data.extend(data)
        print(f"Processed {input_file}")
    else:
        print(f"File not found: {input_file}")

# Write the combined data to the output file
with open(output_file, 'w') as f:
    json.dump(combined_data, f, indent=2)

print(f"Combined data written to {output_file}")
print(f"Total entries: {len(combined_data)}")