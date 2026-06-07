import json

# Check if there's a profile JSON file for Dina
import os
profile_dir = '/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11_apply'
for f in os.listdir(profile_dir):
    if 'dina' in f.lower():
        path = os.path.join(profile_dir, f)
        print(f'File: {f}')
        size = os.path.getsize(path)
        print(f'Size: {size} bytes')
        if size < 500000:
            with open(path) as fh:
                data = json.load(fh)
                print(json.dumps(data, indent=2)[:2000])
        print()
