"""Static balance check for HumanityLedger.

Parses the decision/quest .tres files, then simulates an optimal playthrough
toward each of the 6 endings and reports whether each ending is reachable
(stat conditions + required decisione_chiave), whether the Idolo del Fuoco
stat gate is passable, and whether the mystery can be activated.

No Godot needed. Run: python tools/balance_sim.py
"""
import re
import glob
import os

STATS = ["militare", "tesoro", "diplomazia", "scienza",
         "legge", "spionaggio", "popolo", "costruzione"]
START = 30
POP_START = 40
SMIN, SMAX = 0, 100

DEC_DIR = "data/decisions"
QUEST_DIR = "data/quests"

# Quest order per era (mirror main.gd QUEST_SEQUENZE)
ERA_SEQ = {
    1: ["q_caverna_tutorial", "q_accampamento", "q_confronto", "q_idolo_del_fuoco"],
    2: ["q_corte_si_forma", "q_pressione_imperi", "q_scelta_finale"],
}

# Endings (mirror data/finali/*.tres)
FINALI = {
    "guerra":     ({"militare": 55}, "marciato_contro_impero"),
    "prosperita": ({"tesoro": 50, "popolo": 50}, "commercio_lega"),
    "scienza":    ({"scienza": 55}, "protetto_alchimista"),
    "alleanza":   ({"diplomazia": 55}, "mediato_pace"),
    "industria":  ({"costruzione": 55, "scienza": 45}, "avviato_fonderia"),
    "futura":     ({}, "accolto_la_voce"),
}

MYSTERY_FLAGS = ["accolto_popolo_nebbie", "nebbie_osservati", "sogno_accolto",
                 "ascolta_sogno_condiviso", "pittura_ascoltata",
                 "voce_bosco_ascoltata", "tempio_vuoto_studiato", "canti_trascritti"]
MYSTERY_SOGLIA = 2


def _parse_dict(block, key):
    """Parse an int-valued dict like stat_delta = {"militare": 10}."""
    m = re.search(key + r"\s*=\s*\{([^}]*)\}", block, re.S)
    out = {}
    if not m:
        return out
    for k, v in re.findall(r'"([^"]+)"\s*:\s*(-?\d+)', m.group(1)):
        out[k] = int(v)
    return out


def _parse_keys(block, key):
    """Parse just the keys of a dict (e.g. set_flags = {"x": true}) -> {"x"}."""
    m = re.search(key + r"\s*=\s*\{([^}]*)\}", block, re.S)
    if not m:
        return set()
    return set(re.findall(r'"([^"]+)"\s*:', m.group(1)))


def _parse_str(block, key):
    m = re.search(key + r'\s*=\s*"([^"]*)"', block)
    return m.group(1) if m else ""


def _parse_int(block, key):
    m = re.search(key + r"\s*=\s*(-?\d+)", block)
    return int(m.group(1)) if m else 0


def _blocks(text):
    """Yield (header_line, body) for each [sub_resource]/[resource] section."""
    parts = re.split(r"\n(?=\[)", text)
    for p in parts:
        first = p.splitlines()[0] if p.splitlines() else ""
        yield first, p


def parse_decision(path):
    text = open(path, encoding="utf-8").read()
    effs = {}
    opts = []
    for header, body in _blocks(text):
        if header.startswith("[sub_resource") and "stat_delta" in body and "strategia" not in body:
            sid = re.search(r'id="([^"]+)"', header).group(1)
            effs[sid] = {
                "stat_delta": _parse_dict(body, "stat_delta"),
                "set_flags": _parse_keys(body, "set_flags"),
                "decisione_chiave": _parse_str(body, "add_decisione_chiave"),
                "pop": _parse_int(body, "popolazione_delta"),
            }
        elif header.startswith("[sub_resource") and "strategia" in body:
            eff_ref = re.search(r'effetto\s*=\s*SubResource\("([^"]+)"\)', body)
            opts.append({"eff": eff_ref.group(1) if eff_ref else None})
    options = []
    for o in opts:
        e = effs.get(o["eff"], {"stat_delta": {}, "set_flags": {}, "decisione_chiave": "", "pop": 0})
        options.append(e)
    return options


def parse_quest(path):
    text = open(path, encoding="utf-8").read()
    passi = re.findall(r'res://data/decisions/([^"]+)\.tres', text)
    complete = {"stat_delta": {}, "set_flags": {}, "decisione_chiave": "", "pop": 0}
    for header, body in _blocks(text):
        if header.startswith("[sub_resource"):
            complete = {
                "stat_delta": _parse_dict(body, "stat_delta"),
                "set_flags": _parse_keys(body, "set_flags"),
                "decisione_chiave": _parse_str(body, "add_decisione_chiave"),
                "pop": _parse_int(body, "popolazione_delta"),
            }
    precond_stat = {}
    for header, body in _blocks(text):
        if header.startswith("[resource]"):
            precond_stat = _parse_dict(body, "precondizioni_stat")
    return passi, complete, precond_stat


def apply(state, eff):
    for k, v in eff["stat_delta"].items():
        state["stats"][k] = max(SMIN, min(SMAX, state["stats"][k] + v))
    for f in eff["set_flags"]:
        state["flags"].add(f)
    if eff["decisione_chiave"]:
        state["dc"].add(eff["decisione_chiave"])
    state["pop"] = max(0, state["pop"] + eff["pop"])


def mystery_points(state):
    return sum(1 for f in MYSTERY_FLAGS if f in state["flags"]) + \
        (1 if "accolto_popolo_nebbie" in state["dc"] else 0)


def score_option(eff, target_stats, target_key, want_mystery):
    s = sum(eff["stat_delta"].get(st, 0) for st in target_stats)
    if target_key and eff["decisione_chiave"] == target_key:
        s += 1000
    if want_mystery:
        s += 100 * sum(1 for f in eff["set_flags"] if f in MYSTERY_FLAGS)
        if eff["decisione_chiave"] == "accolto_popolo_nebbie":
            s += 100
    # mild bonus to keep popolo/costruzione up for the Idolo gate
    s += 0.3 * (eff["stat_delta"].get("popolo", 0) + eff["stat_delta"].get("costruzione", 0))
    return s


def simulate(target_stats, target_key, want_mystery):
    state = {"stats": {s: START for s in STATS}, "pop": POP_START, "flags": set(), "dc": set()}
    notes = []
    decisions = {os.path.basename(p)[:-5]: parse_decision(p)
                 for p in glob.glob(f"{DEC_DIR}/*.tres")}
    for era in (1, 2):
        for qid in ERA_SEQ[era]:
            passi, complete, precond = parse_quest(f"{QUEST_DIR}/{qid}.tres")
            for st, req in precond.items():
                if state["stats"][st] < req:
                    notes.append(f"GATE FALLITO {qid}: {st} {state['stats'][st]}<{req}")
            for dname in passi:
                options = decisions.get(dname, [])
                if not options:
                    continue
                # the "voce" gated option (accolto_la_voce) only if mystery active
                feasible = []
                for e in options:
                    if e["decisione_chiave"] == "accolto_la_voce" and mystery_points(state) < MYSTERY_SOGLIA:
                        continue
                    feasible.append(e)
                if not feasible:
                    feasible = options
                best = max(feasible, key=lambda e: score_option(e, target_stats, target_key, want_mystery))
                apply(state, best)
            apply(state, complete)
    return state, notes


def main():
    print("=== BALANCE CHECK ===  (start stat=30, pop=40)\n")
    for name, (cond, key) in FINALI.items():
        want_mystery = (name == "futura")
        state, notes = simulate(set(cond.keys()) or {"scienza"}, key, want_mystery)
        ok_stats = all(state["stats"][s] >= v for s, v in cond.items())
        ok_key = key in state["dc"]
        myst = mystery_points(state) >= MYSTERY_SOGLIA
        reachable = ok_stats and ok_key and (myst if want_mystery else True)
        flag = "OK " if reachable else "FAIL"
        statline = ", ".join(f"{s}={state['stats'][s]}" for s in cond) if cond else "(nessuna)"
        print(f"[{flag}] {name:11s} cond[{statline}] key={key}:{ok_key} "
              f"mystery={mystery_points(state)}{'(needed)' if want_mystery else ''} pop={state['pop']}")
        for n in notes:
            print("        " + n)
    print("\n(le simulazioni sono greedy verso ciascun finale; FAIL = finale non raggiungibile)")


if __name__ == "__main__":
    main()
