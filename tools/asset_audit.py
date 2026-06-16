"""Asset integrity audit for HumanityLedger (no Godot needed).

- Static refs: every res://Assets/... path in *.gd and *.tres -> exists?
- Event illustrations: every Decision.illustrazione_id -> art/eventi/<id>.png exists?
- Orphans: Assets/art image files never referenced statically (best-effort;
  dynamic load("...%d...") paths are listed separately as "dynamic dirs").

Run from repo root: python tools/asset_audit.py
"""
import os
import re
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "Assets")


def res_to_fs(p):
    return os.path.join(ROOT, p[len("res://"):].replace("/", os.sep))


def all_text_files():
    for ext in ("gd", "tres", "tscn"):
        yield from glob.glob(os.path.join(ROOT, "**", f"*.{ext}"), recursive=True)


def main():
    static_refs = set()
    dynamic_dirs = set()
    illu_ids = set()
    ref_re = re.compile(r'res://(Assets|data)/[^"\'\s)]+')
    fmt_re = re.compile(r'"(res://Assets/[^"]*%[ds][^"]*)"')
    illu_re = re.compile(r'illustrazione_id\s*=\s*"([^"]+)"')

    for f in all_text_files():
        txt = open(f, encoding="utf-8", errors="ignore").read()
        for m in ref_re.finditer(txt):
            static_refs.add(m.group(0))
        for m in fmt_re.finditer(txt):
            dynamic_dirs.add(m.group(1))
        for m in illu_re.finditer(txt):
            illu_ids.add(m.group(1))

    # 1) broken static references
    broken = []
    for r in sorted(static_refs):
        if "%" in r:
            continue
        if not os.path.exists(res_to_fs(r)):
            broken.append(r)

    print("=== 1. RIFERIMENTI STATICI ROTTI ===")
    if broken:
        for b in broken:
            print("  MANCA:", b)
    else:
        print("  nessuno (tutti i res:// statici esistono)")

    # 2) event illustrations
    print("\n=== 2. ILLUSTRAZIONI EVENTI (Decision.illustrazione_id) ===")
    evdir = os.path.join(ASSETS, "art", "eventi")
    have = {os.path.splitext(x)[0] for x in os.listdir(evdir)} if os.path.isdir(evdir) else set()
    for i in sorted(illu_ids):
        mark = "ok " if i in have else "MANCA"
        print(f"  [{mark}] {i}")
    extra = sorted(have - illu_ids - {".gitkeep"})
    print("  -- immagini eventi presenti ma non usate da nessuna decisione:")
    for e in extra:
        if e:
            print("     -", e)

    # 3) orphans under art/ (best effort: not in static refs, dir not dynamic)
    print("\n=== 3. ASSET ORFANI (art/, mai referenziati staticamente) ===")
    dyn_prefixes = set()
    for d in dynamic_dirs:
        dyn_prefixes.add(d.split("%")[0])
    referenced_fs = {res_to_fs(r) for r in static_refs if "%" not in r}
    orphan_groups = {}
    for f in glob.glob(os.path.join(ASSETS, "art", "**", "*.*"), recursive=True):
        if f.endswith((".import", ".gitkeep")):
            continue
        res = "res://" + os.path.relpath(f, ROOT).replace(os.sep, "/")
        if f in referenced_fs:
            continue
        if any(res.startswith(p) for p in dyn_prefixes):
            continue  # loaded via dynamic format string
        grp = os.path.dirname(res)
        orphan_groups.setdefault(grp, 0)
        orphan_groups[grp] += 1
    if orphan_groups:
        for g in sorted(orphan_groups):
            print(f"  {orphan_groups[g]:3d}  {g}")
    else:
        print("  nessuno")

    print("\n=== cartelle caricate dinamicamente (load con %d/%s) ===")
    for d in sorted(dynamic_dirs):
        print("  ", d)


if __name__ == "__main__":
    main()
