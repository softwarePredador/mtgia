#!/usr/bin/env python3
"""Add loss reason tracking to battle output lines."""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"

with open(TARGET) as f:
    lines = f.readlines()

# Find the game tracking section
for i, line in enumerate(lines):
    # Add loss_reasons defaultdict
    if 'win_reasons = defaultdict(int)' in line:
        lines.insert(i + 1, '        loss_reasons = defaultdict(int)\n')
        print(f"  Added loss_reasons at line {i+2}")
        break

for i, line in enumerate(lines):
    # Track loss reasons
    if line.strip() == 'elif result == "loss":' and 'losses += 1' in lines[i+1]:
        lines.insert(i + 2, '                loss_reasons[reason] += 1\n')
        print(f"  Added loss tracking at line {i+3}")
        break

for i, line in enumerate(lines):
    # Fix details output to include loss reasons
    if 'win_reasons.items()' in line and 'details' in line:
        lines[i] = '        details_parts = [f"W:{k}={v}" for k, v in win_reasons.items()]\n'
        lines.insert(i+1, '        details_parts += [f"L:{k}={v}" for k, v in loss_reasons.items()]\n')
        lines.insert(i+2, '        details = ", ".join(details_parts) if details_parts else "-"\n')
        print(f"  Fixed details output at line {i+1}")
        break

with open(TARGET, "w") as f:
    f.writelines(lines)
print("DONE")
