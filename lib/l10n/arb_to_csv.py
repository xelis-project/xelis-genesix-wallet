import json
import csv
import os

# Get all .arb files in the current directory
arb_files = [f for f in os.listdir('.') if f.endswith('.arb')]
print(f"Found {len(arb_files)} .arb files: {arb_files}")

# Output CSV file
output_csv = "translations.csv"

# Read all .arb files and collect translations
translations = {}
for file in arb_files:
    print(f"Processing file: {file}")
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
        lang = os.path.splitext(file)[0].split('_')[1]
        for key, value in data.items():
            if key not in translations:
                translations[key] = {}
            translations[key][lang] = value

# Write translations to CSV
print(f"Writing translations to {output_csv}")
with open(output_csv, 'w', newline='', encoding='utf-8') as csvfile:
    fieldnames = ['key'] + [os.path.splitext(file)[0].split('_')[1] for file in arb_files]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    writer.writeheader()
    for key, langs in translations.items():
        row = {'key': key}
        row.update(langs)
        writer.writerow(row)

print(f"Translations have been written to {output_csv}")