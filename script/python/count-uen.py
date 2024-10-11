import json

with open('data/json/combined_uen_no_status.json', 'r') as file:
    data = json.load(file)
    
print(f"Total number of objects: {len(data)}")