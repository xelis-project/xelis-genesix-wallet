import csv
import json
import requests

# URL of the Google Sheet file in CSV format
csv_url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vT4bN-oCf-EbNWiAzzvR_CFr0K6mdD5YQUhG0kt09E5Jf-ohJSy9m2SjJRGUCfodMvfju6ts6u5d0iy/pub?output=csv"

# Download the CSV file
print("Downloading translations...")
response = requests.get(csv_url)
response.raise_for_status()
csv_content = response.content.decode('utf-8')

# Read the CSV content
print("Downloaded! Converting...")
lines = list(csv.reader(csv_content.splitlines()))
languages = lines[0][1:]  # Languages are in the first row, starting from the second column
translations = {lang: {} for lang in languages}

# Convert the CSV content into a dictionary of translations
for row in lines[1:]:
    key = row[0]
    for i, value in enumerate(row[1:]):
        lang = languages[i]
        translations[lang][key] = value.strip()

# Generate .arb files
print("Generating .arb files...")
for lang, content in translations.items():
    arb_file_name = f'app_{lang}.arb'
    with open(arb_file_name, 'w+b') as arb_file:
        json_content = json.dumps(content, ensure_ascii=False, indent=2)
        arb_file.write(json_content.encode('utf-8'))
        arb_file.write(b'\n')  # Ensure the file ends with LF
    print(f"Generated {arb_file_name}")

print("All .arb files have been generated and replaced if they existed.")