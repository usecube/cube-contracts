import csv
import json
import os

############################
# PRINTING FOR ACRA A TO Z #
############################

# # Function to process a single CSV file
# def process_csv(input_csv, output_json):
#     # List to store the extracted data
#     data = []

#     # Read the CSV file and extract required fields
#     with open(input_csv, 'r') as csvfile:
#         reader = csv.DictReader(csvfile)
#         for row in reader:
#             entry = {
#                 'uen': row['uen'],
#                 'entity_name': row['entity_name'],
#                 'entity_status': row['entity_status_description']
#             }
#             data.append(entry)

#     # Write the extracted data to a JSON file
#     with open(output_json, 'w') as jsonfile:
#         json.dump(data, jsonfile, indent=2)

#     print(f"Data has been extracted and saved to {output_json}")

# # Base paths
# base_input_path = '../../data/csv/ACRAInformationonCorporateEntities'
# base_output_path = '../../data/json/'

# # Process files for A to Z
# for letter in range(ord('A'), ord('Z') + 1):
#     input_csv = f"{base_input_path}{chr(letter)}.csv"
#     output_json = f"{base_output_path}{chr(letter)}.json"
    
#     if os.path.exists(input_csv):
#         process_csv(input_csv, output_json)
#     else:
#         print(f"File not found: {input_csv}")

# print("Processing complete.")

############################
# PRINTING FOR ACRA OTHERS #
############################

import csv
import json

# Input and output file paths
input_csv = '../../data/csv/ACRAInformationonCorporateEntitiesOthers.csv'  
output_json = '../../data/json/others.json' 

# List to store the extracted data
data = []

# Read the CSV file and extract required fields
with open(input_csv, 'r') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        entry = {
            'uen': row['uen'],
            'entity_name': row['entity_name'],
            'entity_status': row['entity_status_description']
        }
        data.append(entry)

# Write the extracted data to a JSON file
with open(output_json, 'w') as jsonfile:
    json.dump(data, jsonfile, indent=2)

print(f"Data has been extracted and saved to {output_json}")