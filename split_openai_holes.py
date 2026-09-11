#!/usr/bin/env python3
import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path

TOKEN = re.compile(r'[AaCcHhLlMmQqSsTtVvZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?')
COMMANDS = set('AaCcHhLlMmQqSsTtVvZz')
NARGS = {'M':2,'L':2,'H':1,'V':1,'C':6,'S':4,'Q':4,'T':2,'A':7,'Z':0}

def split_subpaths(d: str):
    toks = [(m.group(), m.start(), m.end()) for m in TOKEN.finditer(d)]
    x = y = sx = sy = 0.0
    cmd = None
    i = 0
    subs = []

    while i < len(toks):
        tok = toks[i][0]
        if tok in COMMANDS:
            cmd = tok
            i += 1
            if cmd.upper() == 'Z':
                x, y = sx, sy
                cmd = None
                continue

        if cmd is None:
            continue

        u = cmd.upper()
        n = NARGS[u]
        if i + n > len(toks) or any(toks[i+k][0] in COMMANDS for k in range(n)):
            continue

        vals = list(map(float, (toks[i+k][0] for k in range(n))))
        rel = cmd.islower()

        if u == 'M':
            nx, ny = vals
            if rel:
                nx, ny = x + nx, y + ny
            command_start = toks[i-1][1]
            subs.append([command_start, toks[i+1][2], nx, ny])
            x, y = nx, ny
            sx, sy = x, y
            cmd = 'l' if rel else 'L'
            i += 2
            continue
        elif u == 'L':
            nx, ny = vals
            x, y = (x + nx, y + ny) if rel else (nx, ny)
        elif u == 'H':
            x = x + vals[0] if rel else vals[0]
        elif u == 'V':
            y = y + vals[0] if rel else vals[0]
        elif u == 'C':
            nx, ny = vals[4], vals[5]
            x, y = (x + nx, y + ny) if rel else (nx, ny)
        elif u == 'S':
            nx, ny = vals[2], vals[3]
            x, y = (x + nx, y + ny) if rel else (nx, ny)
        elif u == 'Q':
            nx, ny = vals[2], vals[3]
            x, y = (x + nx, y + ny) if rel else (nx, ny)
        elif u == 'T':
            nx, ny = vals
            x, y = (x + nx, y + ny) if rel else (nx, ny)
        elif u == 'A':
            nx, ny = vals[5], vals[6]
            x, y = (x + nx, y + ny) if rel else (nx, ny)

        i += n

    result = []
    for idx, (start, first_pair_end, ax, ay) in enumerate(subs):
        end = subs[idx+1][0] if idx + 1 < len(subs) else len(d)
        tail = d[first_pair_end:end].strip()
        result.append(f'M{ax:g} {ay:g}' + (f' {tail}' if tail else ''))
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('svg')
    ap.add_argument('-o', '--out', default='holes')
    args = ap.parse_args()

    root = ET.parse(args.svg).getroot()
    viewbox = root.attrib['viewBox']
    path = next(e for e in root.iter() if e.tag.endswith('path'))
    subs = split_subpaths(path.attrib['d'])

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    # subpath 0 = outer contour, 1.. = holes for this OpenAI SVG
    for i, d in enumerate(subs[1:], 1):
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}"><path d="{d}"/></svg>\n'
        (out / f'hole{i}.svg').write_text(svg)

    print(f'wrote {len(subs)-1} holes to {out}')

if __name__ == '__main__':
    main()
