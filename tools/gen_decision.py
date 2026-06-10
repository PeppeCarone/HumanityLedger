"""Genera file decisione .tres validi da spec compatte, nel formato del progetto.

Evita errori di formato scrivendo a mano 80+ righe per decisione: si scrive la
narrativa + la mappatura (strategia/bersaglio/effetto) e il tool emette il .tres.
Le strategie note mappano sul dominio del consigliere; gli accenti italiani sono
preservati, le virgolette interne vanno gia' scritte come \\" nella spec.
"""
import os

STRAT_DI_DOMINIO = {
    "militare": "scudo", "tesoro": "economico", "diplomazia": "pergamena",
    "scienza": "libro", "legge": "decreto", "spionaggio": "spionaggio",
    "popolo": "rivoluzionaria", "costruzione": "ascia",
}


def _dict(d):
    if not d:
        return "{}"
    righe = ",\n".join('"%s": %s' % (k, _val(v)) for k, v in d.items())
    return "{\n%s\n}" % righe


def _val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    return '"%s"' % v


def _esc(s):
    """Escape per stringhe .tres: backslash e virgolette doppie."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def _arr(a):
    if not a:
        return "[]"
    return "[%s]" % ", ".join('"%s"' % x for x in a)


def genera(spec):
    opts = spec["opzioni"]
    strats = []
    for o in opts:
        s = o["strat"]
        if s not in strats:
            strats.append(s)
    ext = [
        '[ext_resource type="Script" path="res://scripts/data/decision.gd" id="dec"]',
        '[ext_resource type="Script" path="res://scripts/data/decision_option.gd" id="opt"]',
        '[ext_resource type="Script" path="res://scripts/data/effect.gd" id="eff"]',
    ]
    for s in strats:
        ext.append('[ext_resource type="Resource" path="res://data/strategie/%s.tres" id="s_%s"]' % (s, s))
        ext.append('[ext_resource type="Texture2D" path="res://Assets/art/strategie/%s.png" id="t_%s"]' % (s, s))
    subs = []
    opt_ids = []
    for i, o in enumerate(opts):
        ek = "eff_%d" % i
        ok = "opt_%d" % i
        opt_ids.append(ok)
        subs.append(
            '[sub_resource type="Resource" id="%s"]\n'
            'script = ExtResource("eff")\n'
            'stat_delta = %s\n'
            'set_flags = %s\n'
            'unlock_lore = %s\n'
            'unlock_eventi = %s\n'
            'add_decisione_chiave = "%s"\n'
            'add_to_log = ""\n'
            'rapporti_civilta = %s\n'
            'popolazione_delta = %d\n'
            % (ek, _dict(o.get("stat", {})), _dict(o.get("flags", {})),
               _arr(o.get("lore", [])), _arr(o.get("eventi", [])),
               o.get("chiave", ""), _dict(o.get("rapporti", {})), o.get("pop", 0))
        )
        subs.append(
            '[sub_resource type="Resource" id="%s"]\n'
            'script = ExtResource("opt")\n'
            'strategia = ExtResource("s_%s")\n'
            'oggetto_drag = "icona_strategia"\n'
            'icona_drag = ExtResource("t_%s")\n'
            'label_text = "%s"\n'
            'target_consigliere_id = "%s"\n'
            'effetto = SubResource("%s")\n'
            'feedback_testo = "%s"\n'
            % (ok, o["strat"], o["strat"], _esc(o["label"]), o["target"], ek, _esc(o["feedback"]))
        )
    load_steps = len(ext) + len(subs)
    opzioni_lista = ", ".join('SubResource("%s")' % k for k in opt_ids)
    res = (
        'script = ExtResource("dec")\n'
        'id = "%s"\n'
        'era = %d\n'
        'testo_consigliere = "%s"\n'
        'personaggio_id = "%s"\n'
        'opzioni = [%s]\n'
        'tipo_decisione = "%s"\n'
        % (spec["id"], spec.get("era", 1), _esc(spec["testo"]), spec["personaggio"],
           opzioni_lista, spec.get("tipo", "proposta_consigliere"))
    )
    if spec.get("illustrazione"):
        res += 'illustrazione_id = "%s"\n' % spec["illustrazione"]
    testo = (
        '[gd_resource type="Resource" script_class="Decision" load_steps=%d format=3]\n\n'
        % (load_steps + 1)
        + "\n".join(ext) + "\n\n"
        + "\n".join(subs) + "\n"
        + "[resource]\n" + res
    )
    path = "data/decisions/%s.tres" % spec["id"]
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(testo)
    print("scritto", path, "(%d opzioni, %d strategie)" % (len(opts), len(strats)))


# --- Batch nuove decisioni Era 1 -------------------------------------------

DECISIONI = [
    # === q_accampamento: +3 ===
    {
        "id": "d_acc_04_dispute", "era": 1, "personaggio": "era1_murr", "tipo": "proposta_consigliere",
        "testo": "Due famiglie reclamano la stessa pelle di cervo, e le voci si alzano fino a coprire il fuoco. Non è la prima lite, e non sarà l'ultima. Finora ho deciso io, da solo. Ma il popolo cresce. Su cosa fondiamo il giudizio, d'ora in avanti?",
        "opzioni": [
            {"strat": "decreto", "target": "era1_murr", "label": "Incidi una regola che valga per tutti",
             "stat": {"legge": 12}, "flags": {"prima_legge": True},
             "feedback": "Murr incide tre tacche sulla pietra: una per chi caccia, una per chi cuce, una per chi divide. \"Adesso non decido io,\" dice. \"Decide il segno. E il segno non ha fame.\""},
            {"strat": "rivoluzionaria", "target": "era1_aru", "label": "Lascia che sia il popolo a gridare la sentenza",
             "stat": {"popolo": 12, "legge": -3},
             "feedback": "Aru fa decidere il cerchio a voce alta. La pelle va a chi grida più forte. Stasera il popolo si sente padrone di sé; domani qualcuno ricorderà chi ha gridato contro di lui."},
            {"strat": "scudo", "target": "era1_brann", "label": "Spegni la lite con il pugno più forte",
             "stat": {"militare": 9, "popolo": -4},
             "feedback": "Brann mette la pelle sotto il piede e fissa i due contendenti finché abbassano gli occhi. Nessuno la reclama più. Il silenzio che resta non è pace: è paura, e la paura ha buona memoria."},
        ],
    },
    {
        "id": "d_acc_05_nebbie_scambio", "era": 1, "personaggio": "era1_kael", "tipo": "incontro",
        "testo": "Il Popolo delle Nebbie ha lasciato altri doni sul muschio: ossa intagliate, e una pietra liscia che di notte sembra trattenere la luce. Aspettano sul limite del bosco, immobili. Non chiedono niente. Ed è proprio questo che mi gela. Come rispondiamo al loro silenzio?",
        "opzioni": [
            {"strat": "pergamena", "target": "era1_orm", "label": "Rispondi al dono con un dono",
             "stat": {"diplomazia": 11}, "flags": {"accolto_popolo_nebbie": True}, "chiave": "accolto_popolo_nebbie",
             "feedback": "Orm posa accanto alle ossa il nostro miglior coltello di selce e arretra. Al mattino è sparito, e al suo posto c'è un cerchio di pietre attorno al fuoco spento. Un patto, forse. O un avvertimento gentile."},
            {"strat": "spionaggio", "target": "era1_kael", "label": "Seguili fino a dove dormono",
             "stat": {"spionaggio": 12}, "flags": {"nebbie_osservati": True},
             "feedback": "Kael li segue nella bruma per mezza notte. Torna più pallido del solito. \"Non accendono fuochi,\" dice soltanto. \"E cantano la nenia di Lyssa. Ma loro la sanno fino in fondo.\""},
            {"strat": "libro", "target": "era1_lyssa", "label": "Studia la pietra che trattiene la luce",
             "stat": {"scienza": 11}, "flags": {"pietra_luce_studiata": True},
             "feedback": "Lyssa tiene la pietra nel buio e ne guarda il chiarore spegnersi piano, come un respiro. \"Non è la luce del fuoco,\" sussurra. \"È la luce di qualcosa che ci sta guardando indietro.\""},
        ],
    },
    {
        "id": "d_acc_06_acqua", "era": 1, "personaggio": "era1_tev", "tipo": "proposta_consigliere",
        "testo": "La sorgente vicino all'accampamento si è fatta sottile, un filo d'acqua tra i sassi. Con il caldo che arriva non basterà per tutti. Possiamo muoverci ora, prima che diventi un problema di lance invece che di secchi. Da dove partiamo per non restare a secco?",
        "opzioni": [
            {"strat": "ascia", "target": "era1_tev", "label": "Scava un pozzo fin dove l'acqua si nasconde",
             "stat": {"costruzione": 12}, "pop": 3,
             "feedback": "Tev scende nella terra fino a dove il fango si fa freddo. Quando l'acqua sgorga, il popolo esulta come dopo una caccia. In fondo, è la stessa cosa: hanno strappato la vita alla terra."},
            {"strat": "economico", "target": "era1_vesha", "label": "Raziona ogni sorso e fai scorta",
             "stat": {"tesoro": 11, "popolo": -2},
             "feedback": "Vesha mette un guardiano alla sorgente e conta i secchi due volte al giorno. \"L'acqua adesso vale più della carne,\" dice. La sete non uccide nessuno, ma nessuno la ringrazia."},
            {"strat": "libro", "target": "era1_lyssa", "label": "Leggi il cielo per trovare altra acqua",
             "stat": {"scienza": 11},
             "feedback": "Lyssa segue il volo degli uccelli all'alba e indica un avvallamento tra le colline. Là trovano una pozza nascosta. \"L'acqua chiama l'acqua,\" dice. \"Basta ascoltare chi ha già bevuto.\""},
        ],
    },
    # === q_confronto: +3 ===
    {
        "id": "d_con_03_spie", "era": 1, "personaggio": "era1_kael", "tipo": "proposta_consigliere",
        "testo": "Il Clan del Bisonte si muove lungo il fiume più del solito. Posso avvicinarmi alle loro tende, contare le bocche e le lance, capire se preparano la caccia o la guerra. Ma se mi prendono, la guerra arriva di sicuro. Mando l'ombra avanti, o restiamo alla luce?",
        "opzioni": [
            {"strat": "spionaggio", "target": "era1_kael", "label": "Manda l'ombra a contarli di notte",
             "stat": {"spionaggio": 13}, "flags": {"bisonte_spiato": True},
             "feedback": "Kael torna prima dell'alba con la mappa delle loro tende disegnata nel fango del palmo. \"Più lance che bocche,\" dice. \"Un popolo che si arma più di quanto mangia ha già deciso qualcosa.\""},
            {"strat": "scudo", "target": "era1_brann", "label": "Schiera gli uomini in vista, alla luce",
             "stat": {"militare": 12, "diplomazia": -3}, "rapporti": {"clan_bisonte": -5},
             "feedback": "Brann porta i cacciatori sulla riva, lance al sole, perché il Bisonte veda. Il messaggio è chiaro: non ci faremo sorprendere. Ma una mano alzata si può leggere anche come un pugno."},
            {"strat": "pergamena", "target": "era1_orm", "label": "Manda parole prima delle ombre",
             "stat": {"diplomazia": 11}, "rapporti": {"clan_bisonte": 4},
             "feedback": "Orm va al fiume disarmato e parla a lungo con un loro anziano. Torna senza patti ma senza ferite. \"Hanno paura di noi quanto noi di loro,\" dice. \"E la paura, a volte, è una porta.\""},
        ],
    },
    {
        "id": "d_con_04_rito", "era": 1, "personaggio": "era1_aru", "tipo": "mistero",
        "testo": "Prima di alzare l'Idolo il popolo vuole un rito che lo leghi alla pietra. Ma Lyssa dice che la pittura sulla parete è cambiata ancora: il volto senza nome ora guarda dritto al punto dove sorgerà l'Idolo. Facciamo comunque il rito? E in che forma?",
        "opzioni": [
            {"strat": "rivoluzionaria", "target": "era1_aru", "label": "Guida un canto che unisca tutte le voci",
             "stat": {"popolo": 13}, "flags": {"rito_corale": True}, "pop": 4,
             "feedback": "Aru intona una nota sola e il popolo la raccoglie, voce su voce, finché la caverna stessa sembra cantare. Per un istante nessuno ha più freddo, nessuno ha più paura. Poi il canto tace, e sulla parete il volto sembra sorridere."},
            {"strat": "libro", "target": "era1_lyssa", "label": "Lascia che Lyssa interroghi la pittura",
             "stat": {"scienza": 12}, "flags": {"pittura_ascoltata": True},
             "feedback": "Lyssa appoggia la fronte alla parete dipinta e resta immobile a lungo. Quando si stacca, ha gli occhi lucidi. \"Non chiede di essere temuto,\" dice piano. \"Chiede di essere ricordato. E noi stiamo per dargli una pietra in cui abitare.\""},
            {"strat": "decreto", "target": "era1_murr", "label": "Fissa il rito nelle regole degli avi",
             "stat": {"legge": 12, "popolo": -2},
             "feedback": "Murr stabilisce ogni gesto del rito come legge: chi sta davanti, chi porta il fuoco, quando si tace. Tutto è ordinato, tutto è giusto. E qualcosa, nel troppo ordine, si raffredda."},
        ],
    },
    {
        "id": "d_con_05_minaccia", "era": 1, "personaggio": "era1_brann", "tipo": "catastrofe",
        "testo": "Il Bisonte ha bruciato la nostra trappola per pesci e ha piantato nel fango una lancia spezzata: una sfida, non un caso. Il popolo ci guarda e aspetta di sapere che popolo siamo. Come rispondiamo all'affronto?",
        "opzioni": [
            {"strat": "scudo", "target": "era1_brann", "label": "Rispondi colpo su colpo, subito",
             "stat": {"militare": 14, "popolo": 3}, "rapporti": {"clan_bisonte": -12}, "pop": -3,
             "feedback": "Brann guida un assalto notturno alle loro trappole e torna senza perdite, con due prigionieri e una storia da raccontare. Il popolo esulta. Tra i due clan, il fiume da stanotte scorre più stretto e più rosso."},
            {"strat": "pergamena", "target": "era1_orm", "label": "Esigi un risarcimento senza spargere sangue",
             "stat": {"diplomazia": 13}, "rapporti": {"clan_bisonte": 6},
             "feedback": "Orm porta la lancia spezzata al loro accampamento e la pianta davanti all'anziano, in silenzio. Tornano tre ceste di pesce, e nessuna parola. Un affronto pagato non è un amico, ma non è più una ferita aperta."},
            {"strat": "economico", "target": "era1_vesha", "label": "Compra la pace con parte delle scorte",
             "stat": {"tesoro": -6, "popolo": -3}, "rapporti": {"clan_bisonte": 10},
             "feedback": "Vesha manda pelli e sale al Bisonte, storcendo la bocca a ogni dono che parte. \"La pace comprata,\" borbotta, \"si ricompra ogni inverno.\" Ma per ora nessuno affila lance, e l'inverno è vicino."},
        ],
    },
]

if __name__ == "__main__":
    for spec in DECISIONI:
        genera(spec)
    print("fatto:", len(DECISIONI), "decisioni")
