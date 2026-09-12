# 使い方: merge-toml.py <existing> <keep(dotted,comma)> <sources...>
# sources を順に深マージし、keep で指定したキーは existing の値で上書きして TOML を stdout に出す
import sys
import tomllib
from pathlib import Path

import tomli_w


def deep_merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for k, v in b.items():
            out[k] = deep_merge(a[k], v) if k in a else v
        return out
    if isinstance(a, list) and isinstance(b, list):
        return a + [x for x in b if x not in a]
    return b


def get_path(d, path):
    for k in path:
        if not isinstance(d, dict) or k not in d:
            return None
        d = d[k]
    return d


def set_path(d, path, value):
    for k in path[:-1]:
        d = d.setdefault(k, {})
    d[path[-1]] = value


def load(p):
    path = Path(p)
    return tomllib.loads(path.read_text()) if path.exists() else {}


existing_file, keep, *sources = sys.argv[1:]
merged = {}
for src in sources:
    merged = deep_merge(merged, load(src))
existing = load(existing_file)
for key in filter(None, keep.split(",")):
    path = key.split(".")
    value = get_path(existing, path)
    if value is not None:
        set_path(merged, path, value)
sys.stdout.write(tomli_w.dumps(merged))
