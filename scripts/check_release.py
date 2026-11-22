#!/usr/bin/env python3
"""Read-only integrity checks requiring only the Python standard library."""
from pathlib import Path
import csv
from collections import Counter
import hashlib
import json

root = Path(__file__).resolve().parents[1]
def read(name):
    with (root/name).open(newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))
p = read('data/participants.csv')
r = read('data/responses.csv')
k = read('data/scoring_key.csv')
assert len(p) == 165 and len(r) == 1320 and len(k) == 32
participants = {x['participant']: x for x in p}
assert len(participants) == 165
assert len({(x['participant'], x['exercise']) for x in r}) == 1320
assert set(x['participant'] for x in r) == set(participants)
assert set(Counter(x['participant'] for x in r).values()) == {8}
assert set(Counter((x['participant'], x['TTS']) for x in r).values()) == {4}
key = {(x['exercise'], x['choice']): x for x in k}
assert len(key) == 32
assert Counter(x['exercise'] for x in k) == {str(i):4 for i in range(1,9)}
assert all(sum(int(x['correct']) for x in k if x['exercise'] == str(i)) == 1 for i in range(1,9))
for x in r:
    assert (x['exercise'], x['choice']) in key
    pp = participants[x['participant']]
    expected = int((pp['version']=='1' and int(x['exercise'])%2==0) or
                   (pp['version']=='2' and int(x['exercise'])%2==1))
    assert int(x['TTS']) == expected
diagnoses = ['Dyslexia','Dysorthography','Dysgraphia','Dyscalculia']
assert Counter(sum(int(x[d]) for d in diagnoses) for x in p) == {1:38,2:56,3:33,4:38}
for x in p:
    assert all(x[d] in ('0','1') for d in diagnoses)
    for col,hi in [('Vine_general',8),('Vine_reading',6),('Vine_writing',6),('Vine_calculation',6)]:
        assert 0 <= float(x[col]) <= hi
plus = [x for x in k if x['exercise']=='1' and 'più infinito' in x['choice']]
assert len(plus)==1 and plus[0]['correct']=='0' and plus[0]['orientation_correct']=='1'
for x in k:
    if x['exercise']=='8':
        assert int(x['similar_correct']) == int('implica' in x['choice'])
        assert int(x['orientation_correct']) == int('proporzionale' in x['choice'])
accuracy={}
for t in ['0','1']:
    rr=[x for x in r if x['TTS']==t]
    accuracy[t]=sum(int(key[(x['exercise'],x['choice'])]['correct']) for x in rr)/len(rr)
assert round(100*accuracy['0'],1)==45.3 and round(100*accuracy['1'],1)==55.3
symbol = read('reference_results/main/symbol_interaction_fixed_effects.csv')
inter = next(x for x in symbol if x['term']=='TTS:symbol_typeorientation')
assert abs(float(inter['OR'])-.869973765560671)<1e-10
assert abs(float(inter['p_value'])-.444691384216513)<1e-10
manifest = root/'validation/SHA256SUMS.txt'
if manifest.exists():
    for line in manifest.read_text().splitlines():
        digest, name = line.split('  ',1)
        assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest, name
print(json.dumps({'participants':len(p),'responses':len(r),'scoring_options':len(k),
                  'observed_accuracy':accuracy,'checks':'passed'},indent=2))
