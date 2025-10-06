#!/usr/bin/env python3
import os
import json
import sys

def collect_mappings(input_dir, key_field, value_field):
    mapping = {}
    for root, _, files in os.walk(input_dir):
        for fname in files:
            if not fname.endswith(".json"):
                continue
            fpath = os.path.join(root, fname)
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception as e:
                print(f"Error reading {fpath}: {e}", file=sys.stderr)
                continue

            keys = data.get(key_field)
            values = data.get(value_field)

            if not keys or not values:
                continue

            if not isinstance(keys, list):
                keys = [keys]
            if not isinstance(values, list):
                values = [values]

            # Use path relative to input_dir so API can locate files under the same root
            relpath = os.path.relpath(fpath, input_dir)

            for v in values:
                for k in keys:
                    if k and v:
                        key_norm = str(v).lower()
                        if key_norm in mapping and mapping[key_norm] != relpath:
                            # If different files map to same key, prefer existing but warn
                            print(f"Warning: duplicate mapping for {key_norm!r}: keeping {mapping[key_norm]!r}, skipping {relpath!r}", file=sys.stderr)
                            continue
                        mapping[key_norm] = relpath
    return mapping

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 mappings.py input_folder", file=sys.stderr)
        sys.exit(1)

    os.makedirs(f"{input_folder}/mappings", exist_ok=True)

    modelcodes = collect_mappings(input_folder, "boardconfig", "models")
    identifiers = collect_mappings(input_folder, "boardconfig", "identifiers")
    boardconfigs = collect_mappings(input_folder, "boardconfig", "boardconfig")

    with open(f"{input_folder}/mappings/models.json", "w", encoding="utf-8") as f:
        json.dump(modelcodes, f, indent=4, ensure_ascii=False)
        print(f"Wrote {input_folder}/mappings/modelcodes.json")

    with open(f"{input_folder}/mappings/identifiers.json", "w", encoding="utf-8") as f:
        json.dump(identifiers, f, indent=4, ensure_ascii=False)
        print(f"Wrote {input_folder}/mappings/identifiers.json")

    with open(f"{input_folder}//mappings/boardconfigs.json", "w", encoding="utf-8") as f:
        json.dump(boardconfigs, f, indent=4, ensure_ascii=False)
        print(f"Wrote {input_folder}/mappings/boardconfigs.json")

    input_folder = sys.argv[1]
    if not os.path.isdir(input_folder):
        print(f"Error: {input_folder!r} is not a directory", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
