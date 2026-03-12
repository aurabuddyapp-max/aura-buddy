import re
from collections import defaultdict

def parse_errors():
    file_errors = defaultdict(list)
    with open('flutter_analyze_output.txt', 'r', encoding='utf-16le') as f:
        lines = f.readlines()
        
    for line in lines:
        line = line.strip()
        if not line:
            continue
        parts = line.split(' - ')
        if len(parts) >= 3:
            category = parts[0].strip()
            description = parts[1].strip()
            location = parts[2].strip()
            
            # extract file path
            file_path = location.split(':')[0]
            
            if 'error' in category.lower() or 'warning' in category.lower():
                file_errors[file_path].append(f"Line {location.split(':')[1]}: {description}")
                
    for file_path, errors in file_errors.items():
        print(f"\n--- {file_path} ---")
        for error in errors:
            print(f"  {error}")

if __name__ == "__main__":
    parse_errors()
