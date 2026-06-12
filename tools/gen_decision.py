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


# --- Batch espansione Era 1 (2026-06-12): 18 -> 21 --------------------------
# Le notti lunghe (Aru, accampamento), il cacciatore ferito (Orm, confronto),
# il trasporto della pietra (Tev, atto Idolo che aveva 1 sola decisione).

DECISIONI = [
    {
        "id": "d_acc_07_notti", "era": 1, "personaggio": "era1_aru", "tipo": "proposta_consigliere",
        "testo": "Le notti si sono fatte lunghe, e il buio entra nelle teste prima che nei ripari. I piccoli non dormono, i vecchi contano i lupi che cantano oltre il fiume. Il fuoco da solo non basta a tenere insieme un popolo quando il sole se ne va. Come attraversiamo le notti lunghe?",
        "opzioni": [
            {"strat": "rivoluzionaria", "target": "era1_aru", "label": "Raduna tutti al fuoco e canta la memoria",
             "stat": {"popolo": 12},
             "feedback": "Aru canta i nomi di chi ci ha portato fin qui, una notte per nome. I piccoli imparano i ritornelli, i vecchi li correggono sorridendo. Il buio resta fuori dal cerchio di luce."},
            {"strat": "scudo", "target": "era1_brann", "label": "Imponi turni di guardia armata",
             "stat": {"militare": 11, "popolo": -2},
             "feedback": "Brann divide la notte in tre veglie. Lupo che si avvicina, lancia che lo aspetta. Qualcuno sbuffa per il sonno perso, ma i canti dei lupi si allontanano."},
            {"strat": "ascia", "target": "era1_tev", "label": "Alza un cerchio di torce attorno al campo",
             "stat": {"costruzione": 11, "tesoro": -2},
             "feedback": "Tev pianta pali alti quanto un uomo e li corona di fuoco. Il campo diventa un'isola di luce nella pianura nera. Costa grasso e legna ogni notte, ma da lontano sembriamo già un popolo."},
        ],
    },
    {
        "id": "d_con_06_ferito", "era": 1, "personaggio": "era1_orm", "tipo": "incontro",
        "testo": "I cacciatori hanno trovato un uomo del Bisonte nel nostro territorio, la gamba spezzata da una caduta. Respira, ma da solo non camminerà. Possiamo riportarlo ai suoi, tenerlo finché parla, o chiedere qualcosa in cambio della sua vita. Ognuna di queste strade dice chi siamo. Cosa facciamo dell'uomo ferito?",
        "opzioni": [
            {"strat": "pergamena", "target": "era1_orm", "label": "Curalo e riportalo ai suoi",
             "stat": {"diplomazia": 12}, "rapporti": {"clan_bisonte": 10},
             "feedback": "Orm stecca la gamba dell'uomo e lo riporta al fiume su una barella di rami. Il Bisonte osserva in silenzio dall'altra riva. Tre giorni dopo, sulla riva nostra, qualcuno lascia una cesta di pesce affumicato."},
            {"strat": "spionaggio", "target": "era1_kael", "label": "Tienilo finché non parla",
             "stat": {"spionaggio": 12}, "rapporti": {"clan_bisonte": -4},
             "feedback": "Kael si siede accanto al ferito e aspetta. Niente minacce: domande corte, silenzi lunghi. Quando l'uomo torna ai suoi, noi sappiamo quanti sono e cosa temono. Lui non sa di averlo detto."},
            {"strat": "economico", "target": "era1_vesha", "label": "Chiedi un riscatto per la sua vita",
             "stat": {"tesoro": 11, "popolo": -2}, "rapporti": {"clan_bisonte": -8},
             "feedback": "Vesha manda al Bisonte il conto: sette pelli e due lame per riavere il loro cacciatore. Pagano, contando ogni pelle a voce alta perché tutti sentano. Il fiume, da quel giorno, è più freddo."},
        ],
    },
    {
        "id": "d_idolo_00_pietra", "era": 1, "personaggio": "era1_tev", "tipo": "svolta",
        "testo": "La pietra per l'Idolo l'ho trovata: dorme a mezza giornata da qui, grande come quattro uomini e pesante come cento. Si può fare: rulli di tronchi, corde di pelle, braccia. Oppure si può fare in altri modi. Ma una cosa è certa: nessuna pietra cammina da sola. Come la portiamo a casa?",
        "opzioni": [
            {"strat": "ascia", "target": "era1_tev", "label": "Rulli, corde e ingegno",
             "stat": {"costruzione": 12, "scienza": 2},
             "feedback": "Tev stende un sentiero di tronchi e la pietra cammina, un palmo per canto di corda. Quando entra nel campo, nessuno parla. La montagna è venuta da noi."},
            {"strat": "rivoluzionaria", "target": "era1_aru", "label": "Tutto il popolo, una sola corda",
             "stat": {"popolo": 12, "costruzione": 2},
             "feedback": "Aru lega il canto al passo: tira-respira, tira-respira. Vecchi, piccoli, cacciatori, tutti sulla stessa corda. La pietra arriva, e il popolo scopre il proprio peso."},
            {"strat": "pergamena", "target": "era1_orm", "label": "Chiedi le braccia del Bisonte",
             "stat": {"diplomazia": 11, "tesoro": -3}, "rapporti": {"clan_bisonte": 8},
             "feedback": "Orm porta al Bisonte una proposta semplice: braccia oggi, gratitudine domani. Vengono in venti, e guardano la pietra con sospetto e meraviglia. Due popoli, una pietra sola."},
        ],
    },
]

# --- Batch catastrofi Era 2 (2026-06-12, commit ce78968) ---------------------
# Completa D020: Peste, Ribellione, Tentato Assassinio (illustrazioni plague/
# rebellion/assassination gia' in Assets/art/eventi). Saekh propone per la
# prima volta. Lore nuove da registrare in ledger_screen.gd LORE_REGISTRY.

_DECISIONI_CATASTROFI_ARCHIVIO = [
    {
        "id": "d_corte_17_peste", "era": 2, "personaggio": "era2_iove", "tipo": "catastrofe",
        "illustrazione": "plague",
        "testo": "Tre morti alla porta del fiume, dieci giorni fa. Ieri ventisette, e stamattina i carri non bastavano. Ho misurato il passo del morbo come misuro le stelle: raddoppia ogni quattro giorni, e non ha ancora toccato i quartieri alti. Le erbe amare che bruciano nei vicoli non fermeranno la proporzione. Come fermiamo la peste?",
        "opzioni": [
            {"strat": "libro", "target": "era2_iove", "label": "Isola il morbo e distilla un rimedio",
             "stat": {"scienza": 12, "popolo": 2}, "flags": {"peste_studiata": True}, "lore": ["lore_peste"],
             "feedback": "Iove trasforma una taverna in spezieria e scompone il morbo come un metallo impuro. Il rimedio arriva tardi per molti, ma arriva. \"Ogni piaga,\" annota, \"è una domanda posta male.\""},
            {"strat": "decreto", "target": "era2_maren", "label": "Mura i quartieri colpiti per decreto",
             "stat": {"legge": 11, "popolo": -6}, "pop": -2, "lore": ["lore_peste"],
             "feedback": "Maren firma la quarantena senza alzare lo sguardo. Le porte dei vicoli vengono murate, i viveri calati con le corde. Il morbo si spegne in fretta; certe grida, più lentamente."},
            {"strat": "rivoluzionaria", "target": "era2_karro", "label": "Porta cure e pane in mezzo ai malati",
             "stat": {"popolo": 12, "tesoro": -5}, "pop": -1, "lore": ["lore_peste"],
             "feedback": "Karro entra nei quartieri bassi quando tutti ne scappano, e mezza piazza lo segue con erbe e pane. Qualcuno di loro non torna. Ma il popolo non dimentica chi è rimasto."},
        ],
    },
    {
        "id": "d_corte_18_ribellione", "era": 2, "personaggio": "era2_calden", "tipo": "catastrofe",
        "illustrazione": "rebellion",
        "testo": "Il quartiere delle fornaci ha bruciato i registri delle tasse e rovesciato i carri alle porte. Barricate alte un uomo, e dietro gente che conosco per nome. Stanotte ho riportato due feriti miei e tre dei loro. Posso riprendermi le strade prima dell'alba, ma il prezzo lo decidete voi. Cosa facciamo della rivolta?",
        "opzioni": [
            {"strat": "scudo", "target": "era2_calden", "label": "Sfonda le barricate prima dell'alba",
             "stat": {"militare": 12, "popolo": -8}, "pop": -2, "lore": ["lore_ribellione"],
             "feedback": "Le barricate cadono in un'ora. Calden conta i feriti a voce alta, uno per uno, perché il consiglio li senta. L'ordine è tornato: brucia ancora, ma è tornato."},
            {"strat": "rivoluzionaria", "target": "era2_karro", "label": "Scavalca la barricata e ascolta",
             "stat": {"popolo": 12, "legge": -4}, "lore": ["lore_ribellione"],
             "feedback": "Karro scavalca la barricata da solo, a mani aperte, e si siede sul carro rovesciato. Parlano fino all'alba. Le fornaci si riaccendono: il regno ha piegato l'orgoglio, non la schiena."},
            {"strat": "decreto", "target": "era2_maren", "label": "Processa i capi, grazia chi depone",
             "stat": {"legge": 11, "popolo": -3}, "lore": ["lore_ribellione"],
             "feedback": "Maren istruisce il processo nella piazza stessa, davanti alle fornaci spente. Tre condanne, lette piano; per tutti gli altri, la grazia. La legge mostra prima il peso, poi la mano aperta."},
        ],
    },
    {
        "id": "d_corte_19_assassinio", "era": 2, "personaggio": "era2_saekh", "tipo": "catastrofe",
        "illustrazione": "assassination",
        "testo": "Una lama, stanotte. Tre passi dalla camera del consiglio. Il mio corvo l'ha fermata; non chiedete come. L'uomo tace, ma la moneta cucita nel suo mantello non è del regno, non è dell'Impero, non è della Lega. Qualcuno vuole il trono vuoto prima della grande scelta. Fuori da questa stanza, nessuno sa nulla. Rispondiamo nell'ombra, o alla luce?",
        "opzioni": [
            {"strat": "spionaggio", "target": "era2_saekh", "label": "Risali il filo nell'ombra, fino al mandante",
             "stat": {"spionaggio": 12, "diplomazia": 2}, "lore": ["lore_lama_buio"],
             "feedback": "Saekh sparisce per nove giorni. Torna con un nome che non pronuncia: lo posa scritto su un frammento di cera, lo fa leggere al consiglio, poi lo scioglie alla candela. \"Sanno che sappiamo,\" sussurra. \"Adesso la paura ha cambiato casa.\""},
            {"strat": "decreto", "target": "era2_maren", "label": "Processalo alla luce, davanti al regno",
             "stat": {"legge": 12, "popolo": 3}, "lore": ["lore_lama_buio"],
             "feedback": "Maren mette il sicario alla sbarra nella sala aperta, porte spalancate. Il regno guarda, e capisce che la corona non trema. Chi ha pagato la lama, da qualche parte, smette di sorridere."},
            {"strat": "scudo", "target": "era2_calden", "label": "Raddoppia le guardie e sigilla la corte",
             "stat": {"militare": 10, "diplomazia": -4}, "lore": ["lore_lama_buio"],
             "feedback": "Calden chiude la corte come un pugno: turni doppi, porte contate, ospiti perquisiti. Nessuna lama passerà più. Nemmeno, temono gli ambasciatori, una parola amica."},
        ],
    },
]

# --- Batch nuove decisioni Era 2 (2026-06-11, commit 05728d2) ---------------
# Espansione 9->16 per avvicinarsi al target D031 (~20-25 decisioni/era).
# Valorizza Vorrik/Saekh/Maren; intreccia Impero del Sole, Lega delle Coste e
# il mystery (canti_trascritti conta in mystery_punti). Batch precedente
# (Era 1, commit ecc2796) rimosso: i .tres sono gia' generati.

_DECISIONI_ERA2_ARCHIVIO = [
    # === q_corte_si_forma (atto 1): +2 ===
    {
        "id": "d_corte_10_moneta", "era": 2, "personaggio": "era2_vorrik", "tipo": "proposta_consigliere",
        "testo": "I mercanti barattano sale con ferro e pelli con grano, e ogni scambio finisce in lite. Un regno che conta in dieci misure diverse non conta niente: lo dico da quando avevamo una sola bilancia. Possiamo battere moneta con il sigillo del regno, o mettere ordine in altro modo. Come ordiniamo la ricchezza del regno?",
        "opzioni": [
            {"strat": "economico", "target": "era2_vorrik", "label": "Batti moneta con il sigillo del regno",
             "stat": {"tesoro": 13, "scienza": 2}, "flags": {"moneta_regno": True},
             "feedback": "Vorrik pesa il primo conio sul palmo come fosse un figlio. \"Da oggi il regno sa quanto vale,\" dice freddo. \"E sa quanto gli si deve. Sono due cose diverse, e le voglio scritte entrambe.\""},
            {"strat": "decreto", "target": "era2_maren", "label": "Fissa per legge pesi e misure uguali per tutti",
             "stat": {"legge": 12, "tesoro": 3},
             "feedback": "Maren detta la tavola delle misure e la fa incidere alle porte del mercato. \"Una bilancia truccata,\" sentenzia, \"ruba due volte: il grano oggi, la fiducia per sempre.\""},
            {"strat": "rivoluzionaria", "target": "era2_karro", "label": "Lascia che la piazza fissi i suoi prezzi",
             "stat": {"popolo": 11, "tesoro": -3},
             "feedback": "Karro porta la decisione al mercato e la piazza si regola da sé, a voce alta, come ha sempre fatto. I conti di Vorrik ne escono storti, ma la gente sorride contando il resto."},
        ],
    },
    {
        "id": "d_corte_11_strade", "era": 2, "personaggio": "era2_lena", "tipo": "proposta_consigliere",
        "testo": "La collina di pietra è forte, ma un regno non è la sua capitale: è la strada che la lega ai campi. Dopo le piogge i carri affondano fino al mozzo e i villaggi restano soli per intere lune. Ho squadre, pietra e braccia per un solo grande cantiere. Dove poso la prossima pietra?",
        "opzioni": [
            {"strat": "ascia", "target": "era2_lena", "label": "Lastrica le strade verso i villaggi",
             "stat": {"costruzione": 13, "popolo": 3}, "pop": 2,
             "feedback": "Lena posa il lastricato miglio dopo miglio, e dietro le sue squadre i villaggi si avvicinano alla capitale senza muoversi di un passo. \"Le mura difendono,\" dice. \"Le strade uniscono. Servivano prima queste.\""},
            {"strat": "economico", "target": "era2_vorrik", "label": "Metti pedaggi su ponti e valichi",
             "stat": {"tesoro": 12, "popolo": -3},
             "feedback": "Vorrik piazza gabellieri a ogni ponte e conta ciò che passa. Le casse si gonfiano a vista. Sui valichi, i carrettieri imparano una nuova bestemmia con il suo nome dentro."},
            {"strat": "pergamena", "target": "era2_sereth", "label": "Apri una via maestra verso le corti vicine",
             "stat": {"diplomazia": 11, "tesoro": 2}, "rapporti": {"lega_coste": 4},
             "feedback": "Sereth fa tracciare la via verso ovest e manda inviti lungo tutto il percorso. Le prime carovane della Lega arrivano con stoffe, spezie e domande cortesi su quanto siamo ricchi davvero."},
        ],
    },
    # === q_pressione_imperi (atto 2): +3 ===
    {
        "id": "d_corte_12_corvo", "era": 2, "personaggio": "era2_saekh", "tipo": "proposta_consigliere",
        "testo": "Un uomo. Preso stanotte, sulle mura. Copiava i camminamenti su un rotolo... e nella fodera, cucito, il sigillo del Sole. Nessuno sa che lo abbiamo noi. Nemmeno l'Impero. Per ora. Cosa ne facciamo del corvo dell'Impero?",
        "opzioni": [
            {"strat": "spionaggio", "target": "era2_saekh", "label": "Rigiralo e rimandalo a casa con notizie false",
             "stat": {"spionaggio": 13, "militare": 2}, "flags": {"corvo_doppio": True},
             "feedback": "Saekh parla con il prigioniero una notte intera, da solo. All'alba l'uomo riparte verso est, con il suo rotolo... ridisegnato. \"Ora le nostre mura,\" sussurra Saekh, \"sono alte il doppio. Sulla carta.\""},
            {"strat": "decreto", "target": "era2_maren", "label": "Processalo alla luce, davanti al regno",
             "stat": {"legge": 12, "diplomazia": -3}, "rapporti": {"impero_sole": -8},
             "feedback": "Maren istruisce il processo nella piazza grande, atto per atto, senza alzare mai la voce. La sentenza è esilio. Il regno impara che la legge vale anche per le ombre. L'Impero impara che li prendiamo."},
            {"strat": "pergamena", "target": "era2_sereth", "label": "Restituiscilo all'Impero con una scorta d'onore",
             "stat": {"diplomazia": 12}, "rapporti": {"impero_sole": 8},
             "feedback": "Sereth riconsegna l'uomo al confine con doni e una lettera squisita che non nomina mai la parola spia. L'Impero capisce tre cose: sappiamo, non temiamo, e preferiamo parlare."},
        ],
    },
    {
        "id": "d_corte_13_granai", "era": 2, "personaggio": "era2_vorrik", "tipo": "catastrofe",
        "illustrazione": "crisi_economica",
        "testo": "I conti sono questi: le piogge lunghe hanno marcito il raccolto, i granai sono a un terzo e i mercanti chiedono il triplo per il grano che resta. L'inverno non aspetta i nostri bilanci. Da dove prendiamo il pane che manca?",
        "opzioni": [
            {"strat": "economico", "target": "era2_vorrik", "label": "Compra il grano della Lega a qualunque prezzo",
             "stat": {"tesoro": -8, "diplomazia": 4, "popolo": 4}, "rapporti": {"lega_coste": 10}, "pop": 2,
             "feedback": "Vorrik firma il contratto con la mascella serrata: le navi della Lega scaricano grano per tutto l'autunno. \"Pago,\" dice. \"Ma che sia scritto: quando le parti si invertiranno, ricorderò il prezzo che hanno fatto.\""},
            {"strat": "rivoluzionaria", "target": "era2_karro", "label": "Apri le riserve del regno alla piazza",
             "stat": {"popolo": 13, "tesoro": -5}, "pop": 3,
             "feedback": "Karro spalanca i granai del regno e distribuisce con le sue mani, un sacco per famiglia, davanti a tutti. \"Il regno siete voi,\" grida. \"Quello che era suo era già vostro.\" La piazza non lo dimenticherà."},
            {"strat": "spionaggio", "target": "era2_saekh", "label": "Sottrai i convogli diretti all'Impero",
             "stat": {"spionaggio": 12, "tesoro": 5}, "rapporti": {"impero_sole": -10},
             "feedback": "Saekh non racconta come, e nessuno chiede. I carri arrivano di notte, senza insegne, pieni di grano con il marchio del Sole raschiato via. Il popolo mangia. Da est, prima o poi, qualcuno verrà a contare i carri."},
        ],
    },
    {
        "id": "d_corte_14_pellegrini", "era": 2, "personaggio": "era2_maren", "tipo": "mistero",
        "testo": "Ogni notte la gente si raduna al tempio che nessuno ha costruito. Cantano una nenia che nessuno ricorda di avere imparato, e i bambini la cantano meglio dei vecchi. Ho cercato nei codici: la legge non ha una riga su questo. Cosa facciamo dei pellegrini del tempio?",
        "opzioni": [
            {"strat": "libro", "target": "era2_iove", "label": "Trascrivi il canto e cercane la misura",
             "stat": {"scienza": 12}, "flags": {"canti_trascritti": True},
             "feedback": "Iove annota il canto in cifre e intervalli, nota dopo nota, e impallidisce sulle proporzioni. \"Le voci salgono come le stelle d'inverno,\" dice. \"Esatte. Questa melodia non è nata in una gola umana.\""},
            {"strat": "decreto", "target": "era2_maren", "label": "Vieta i raduni dopo il tramonto",
             "stat": {"legge": 12, "popolo": -4},
             "feedback": "Maren pesa il divieto parola per parola e lo fa affiggere alle porte. La notte torna silenziosa e ordinata. Ma nelle case, sottovoce, con le imposte chiuse, il canto continua."},
            {"strat": "rivoluzionaria", "target": "era2_karro", "label": "Scendi in piazza e canta con loro",
             "stat": {"popolo": 12}, "pop": 2,
             "feedback": "Karro canta con i pellegrini fino all'alba, la voce roca in mezzo alle altre. \"Non so cosa dica il canto,\" ammette poi. \"Ma so che la piazza non era mai stata così unita. E questo, di solito, lo so usare.\""},
        ],
    },
    # === q_scelta_finale (atto 3): +2 ===
    {
        "id": "d_corte_15_memoria", "era": 2, "personaggio": "era2_maren", "tipo": "svolta",
        "testo": "Gli scribi hanno riempito la prima sala dell'archivio: trattati, sentenze, conti, e le storie che i vecchi giurano di avere vissuto. Lo spazio non basta per tutto, e ciò che non viene tramandato muore con chi lo ricorda. Pronuncio raramente parole solenni, ma questa lo è: cosa tramandiamo di ciò che siamo stati?",
        "opzioni": [
            {"strat": "decreto", "target": "era2_maren", "label": "Incidi leggi e sentenze nella pietra",
             "stat": {"legge": 13, "costruzione": 2},
             "feedback": "Maren sceglie le cento sentenze che hanno retto il regno e le fa incidere nel granito dell'archivio. \"Le storie consolano,\" dice. \"Le leggi proteggono. Chi verrà dopo capirà chi eravamo da come giudicavamo.\""},
            {"strat": "libro", "target": "era2_iove", "label": "Salva i numeri, le mappe e le misure",
             "stat": {"scienza": 12, "tesoro": 2},
             "feedback": "Iove copia mappe, conteggi e proporzioni su pergamena trattata per durare. \"Le opinioni invecchiano,\" dice. \"Le misure no. Chi saprà quanto pesava il nostro grano saprà rifare tutto il resto.\""},
            {"strat": "rivoluzionaria", "target": "era2_karro", "label": "Affida le storie alla voce del popolo",
             "stat": {"popolo": 12, "legge": -2},
             "feedback": "Karro raduna i cantastorie e affida loro le vicende del regno, da ripetere a ogni fuoco e a ogni fiera. Qualche dettaglio cambierà a ogni racconto. Ma una storia che cammina vive più a lungo di una che sta ferma."},
        ],
    },
    {
        "id": "d_corte_16_vigilia", "era": 2, "personaggio": "era2_calden", "tipo": "proposta_consigliere",
        "testo": "Lo sento come si sente un temporale dietro i monti. L'Impero arma le legioni, la Lega ritira le navi dai porti lontani, e le fonderie di Lena scaldano metalli giorno e notte. Qualunque strada il consiglio sceglierà, il regno deve arrivarci in piedi. Come usiamo il tempo che resta?",
        "opzioni": [
            {"strat": "scudo", "target": "era2_calden", "label": "Richiama ogni lancia e presidia i passi",
             "stat": {"militare": 13, "tesoro": -3},
             "feedback": "Calden richiama i veterani e mette guarnigioni su ogni valico. \"Le ferite peggiori,\" dice brusco, \"le ho viste su chi pensava di avere ancora tempo. Noi saremo già in piedi quando busseranno.\""},
            {"strat": "economico", "target": "era2_vorrik", "label": "Riempi granai e casse fino all'orlo",
             "stat": {"tesoro": 12, "popolo": 2},
             "feedback": "Vorrik compra, accumula, sigilla. Granai pieni, casse piene, debiti riscossi fino all'ultimo conio. \"Le guerre,\" dice freddo, \"le vince chi può permettersi di perderne un pezzo.\""},
            {"strat": "pergamena", "target": "era2_sereth", "label": "Manda messi a ogni corte, anche nemica",
             "stat": {"diplomazia": 12}, "rapporti": {"impero_sole": 4, "lega_coste": 4},
             "feedback": "Sereth spedisce messi in ogni direzione, con parole cucite su misura per ciascuna corte. \"Quando il temporale arriva,\" osserva, \"conviene che tutti ricordino di averci stretto la mano. Anche chi sperava di no.\""},
        ],
    },
]

# --- Batch Era 1 (gia' generato, commit ecc2796) -----------------------------

_DECISIONI_ERA1_ARCHIVIO = [
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
