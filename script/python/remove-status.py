import json
import os

# Get the current script's directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the JSON file
json_path = os.path.join(script_dir, '..', '..', 'data', 'json', 'combined_uen.json')

# Read the JSON file
with open(json_path, 'r') as file:
    data = json.load(file)

# Remove 'entity_status' from each object
for item in data:
    if 'entity_status' in item:
        del item['entity_status']

# Construct the path for the output file
output_path = os.path.join(script_dir, '..', '..', 'data', 'json', 'combined_uen_no_status.json')

# Write the updated data back to the file
with open(output_path, 'w') as file:
    json.dump(data, file, indent=2)

print("'entity_status' has been removed from all objects in the JSON file.")
print(f"The updated data has been saved to {output_path}")