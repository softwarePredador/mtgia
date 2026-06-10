L = open('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py').readlines()

for i, l in enumerate(L):
    if 'creature.get("is_commander")' in l and i + 1 < len(L) and 'command_zone.append' in L[i+1]:
        del L[i+1]
        del L[i+1]
        ins = [
            '        # v9: Commander replacement (CR 903.9a) — owner MAY move to CZ\n',
            '        if owner.is_human:\n',
            '            owner.command_zone.append(creature)\n',
            '            return "command_zone"\n',
            '        else:\n',
            '            import random as _cr\n',
            '            if _cr.random() < 0.7:\n',
            '                owner.command_zone.append(creature)\n',
            '                return "command_zone"\n',
        ]
        for j, nl in enumerate(ins):
            L.insert(i+1+j, nl)
        print('APPLIED at line', i+1)
        break

open('/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py', 'w').writelines(L)
print('DONE')
