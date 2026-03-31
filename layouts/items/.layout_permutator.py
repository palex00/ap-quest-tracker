"""
Layout Permutator
=================
Generates permutations of a JSON layout file by toggling feature groups on/off.

HOW TO USE:
1. Edit the GROUPS dictionary below to match your layout file.
   - Each key is a segment that appears in the filename (between underscores).
   - Each value is a list of item strings that belong to that group inside the JSON.
2. Run the script: python layout_permutator.py
3. Enter the path to your input JSON file when prompted.
4. Output files are written to the same directory as the input file.

EXAMPLE:
    GROUPS = {
        "slots": ["slotdigit_1", "slotdigit_2", "slotdigit_3"],
        "signs": ["visibility_signs"],
        "grass": ["visibility_grass"],
        "shop":  ["auto_shop_markoff"],
    }
    Input file: settings_quick_slots_signs_grass_shop.json
    Output: 15 permutated files (all combos except the all-on original).
"""

import json
import copy
import os
import sys
from itertools import product

# =============================================================================
# USER CONFIG — Edit this section to match your layout file
# =============================================================================
GROUPS = {
    "hard": ["healthupgrade"],
    "hammer": ["hammer"],
}
# =============================================================================


def prompt_for_file():
    """Prompt the user for the input file path and validate it."""
    path = input("Enter the path to the input JSON file: ").strip()

    # Remove surrounding quotes if the user dragged the file in
    if (path.startswith('"') and path.endswith('"')) or \
       (path.startswith("'") and path.endswith("'")):
        path = path[1:-1]

    if not os.path.isfile(path):
        print(f"ERROR: File not found: {path}")
        sys.exit(1)

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON in file: {e}")
        sys.exit(1)

    return path, data


def parse_filename(filepath, group_names):
    """
    Parse the filename to find the base name and the order of group segments.

    Returns:
        base_name (str): The filename stem with all group segments removed.
        ordered_groups (list): Group names in the order they appear in the filename.
    """
    stem = os.path.splitext(os.path.basename(filepath))[0]  # e.g. "settings_quick_slots_signs_grass_shop"
    ext = os.path.splitext(filepath)[1]  # e.g. ".json"

    # Split into segments by underscore
    segments = stem.split("_")

    # Find which segments are group names and record their positions
    ordered_groups = []
    group_positions = set()

    for i, seg in enumerate(segments):
        if seg in group_names:
            ordered_groups.append(seg)
            group_positions.add(i)

    # Validate: every group in config must appear in the filename
    missing = set(group_names) - set(ordered_groups)
    if missing:
        print(f"ERROR: The following group names were not found in the filename: {', '.join(sorted(missing))}")
        print(f"  Filename segments: {segments}")
        print(f"  Expected groups:   {sorted(group_names)}")
        sys.exit(1)

    # Base name is the remaining segments joined back together
    base_segments = [seg for i, seg in enumerate(segments) if i not in group_positions]
    base_name = "_".join(base_segments)

    return base_name, ordered_groups, ext


def remove_items_recursive(obj, items_to_remove):
    """
    Recursively walk a JSON structure and remove matching string entries.
    Prunes empty arrays left behind after removal.

    Returns the cleaned object, or None if the object itself should be pruned.
    """
    if isinstance(obj, dict):
        new_dict = {}
        for k, v in obj.items():
            cleaned = remove_items_recursive(v, items_to_remove)
            if cleaned is not None:
                new_dict[k] = cleaned
        return new_dict

    elif isinstance(obj, list):
        new_list = []
        for item in obj:
            if isinstance(item, str) and item in items_to_remove:
                continue  # Remove this string entry
            cleaned = remove_items_recursive(item, items_to_remove)
            if cleaned is not None:
                new_list.append(cleaned)
        # Prune empty arrays
        if len(new_list) == 0:
            return None
        return new_list

    else:
        return obj


def build_filename(base_name, ordered_groups, enabled_groups, ext):
    """
    Reconstruct a filename from the base name and enabled groups in original order.
    """
    parts = [base_name]
    for g in ordered_groups:
        if g in enabled_groups:
            parts.append(g)

    return "_".join(parts) + ext


def main():
    if not GROUPS:
        print("ERROR: The GROUPS config is empty. Please edit the script and define your groups.")
        sys.exit(1)

    print("Layout Permutator")
    print("=" * 40)
    print(f"Configured groups: {len(GROUPS)}")
    for name, items in GROUPS.items():
        print(f"  {name}: {', '.join(items)}")
    print()

    # Prompt for input file
    filepath, data = prompt_for_file()
    output_dir = os.path.dirname(filepath) or "."

    # Parse filename
    group_names = set(GROUPS.keys())
    base_name, ordered_groups, ext = parse_filename(filepath, group_names)

    total_permutations = 2 ** len(ordered_groups) - 1  # Exclude all-on
    print(f"\nBase name: {base_name}")
    print(f"Group order in filename: {' → '.join(ordered_groups)}")
    print(f"Permutations to generate: {total_permutations}")
    print()

    # Generate all on/off combos (True=on, False=off), skip all-on
    generated = 0
    for combo in product([True, False], repeat=len(ordered_groups)):
        if all(combo):
            continue  # Skip all-on (that's the original file)

        enabled_groups = {g for g, on in zip(ordered_groups, combo) if on}

        # Collect all items that should be removed (from disabled groups)
        items_to_remove = set()
        for g, on in zip(ordered_groups, combo):
            if not on:
                items_to_remove.update(GROUPS[g])

        # Deep copy and clean the JSON
        cleaned_data = remove_items_recursive(copy.deepcopy(data), items_to_remove)

        # Build output filename
        out_name = build_filename(base_name, ordered_groups, enabled_groups, ext)
        out_path = os.path.join(output_dir, out_name)

        # Write
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(cleaned_data, f, indent=4)

        generated += 1
        status = ", ".join(f"{g}={'ON' if on else 'OFF'}" for g, on in zip(ordered_groups, combo))
        print(f"  [{generated}/{total_permutations}] {out_name}  ({status})")

    print(f"\nDone! Generated {generated} files in: {os.path.abspath(output_dir)}")


if __name__ == "__main__":
    main()
