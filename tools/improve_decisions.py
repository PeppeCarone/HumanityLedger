# -*- coding: utf-8 -*-
"""Rewrite decision prompts + option labels for clarity.

The player must understand WHAT is being asked without any stat/approach hint
(that stays hidden by design).

- testo_consigliere -> direct, concrete situation ending in an explicit question.
- label_text -> a clear, self-standing imperative answer to that question.
  No stat/approach is exposed here.

Run from project root:  python tools/improve_decisions.py
"""
import glob
import os
import re

# id -> (prompt, [clear self-standing option labels, in option order])
DATA = {
    "d_acc_01_caccia": (
        "Brann: fuori dalla caverna la selvaggina è più grande e più sveglia. La prima caccia dirà se il popolo mangia o teme. Come la guidiamo?",
        ["Carica la preda di petto", "Organizza una battuta coordinata", "Leggi le tracce e tendi agguati"],
    ),
    "d_acc_02_sogno_condiviso": (
        "Lyssa: questa notte Murr ha sognato il mio stesso sogno - il volto senza nome, la voce sotto la pietra. Non è un caso. Come trattiamo questo presagio?",
        ["Ascolta e interpreta il sogno", "Annota e archivia il presagio", "Ignora: è solo la fame"],
    ),
    "d_acc_03_costruzione": (
        "Tev: la terra qui regge il peso. Possiamo costruire qualcosa che resti più di noi. Da dove partiamo a fondare l'accampamento?",
        ["Alza capanne di pietra", "Orienta il campo con gli astri", "Costruisci prima il magazzino"],
    ),
    "d_caverna_01_apertura": (
        "Lyssa: ho sognato pietra, pioggia e un volto senza nome - un presagio di tempi duri. Su cosa puntiamo per superarli?",
        ["Prepara la caccia", "Studia i segni", "Cerca un patto coi vicini"],
    ),
    "d_caverna_02_scorte": (
        "Vesha: sette pelli per sei lune, e il fondo della cesta è vicino. Le scorte non bastano all'inverno. Come le facciamo durare?",
        ["Raziona con la mano dura", "Studia il territorio per nuove risorse", "Tratta col Popolo delle Nebbie"],
    ),
    "d_caverna_03_sogno": (
        "Murr: il sogno bussa di nuovo. Le ossa antiche dicono una cosa, il fuoco un'altra. A chi diamo retta prima di lasciare la caverna?",
        ["Torna alle regole degli avi", "Affidati alla visione del sogno", "Erigi un altare al presagio"],
    ),
    "d_caverna_04_nebbie": (
        "Kael: ombre al limite del bosco - non bestie. Portano ossa intagliate e tengono abbassata la lancia. Il Popolo delle Nebbie ci osserva. Cosa offriamo allo straniero?",
        ["Scambia segni e doni", "Scaccia gli intrusi", "Osservali in silenzio prima di agire"],
    ),
    "d_caverna_05_inverno": (
        "Murr: il Grande Freddo è tornato, come nelle storie antiche. Il fuoco non basta, sette notti senza sole. Come salviamo il popolo dal gelo?",
        ["Scava un riparo profondo", "Tenta una caccia nel gelo", "Leggi il cielo e raziona con metodo"],
    ),
    "d_caverna_06_uscita": (
        "Aru: la caverna ci ha cresciuti ma è diventata stretta. Tre sentieri si aprono oltre la soglia. Dove portiamo il fuoco del popolo?",
        ["Verso il fiume, tra gli altri popoli", "Verso i monti difendibili", "Verso la pianura da coltivare"],
    ),
    "d_con_01_bisonte": (
        "Kael: un inviato del Clan del Bisonte è alle capanne. Sono più numerosi di noi e tengono il fiume. Vuole parlare. Come lo riceviamo?",
        ["Offrigli un patto", "Mostragli le lance", "Fingi accordo e seguine le tracce"],
    ),
    "d_con_02_pietra": (
        "Aru: il popolo vuole un centro, qualcosa che dica chi siamo. Prima di erigere l'Idolo servono la pietra e le mani. Da dove partiamo?",
        ["Cava la grande pietra", "Raduna la gente attorno all'impresa", "Indaga la pittura mutata da sola"],
    ),
    "d_corte_01_eredita": (
        "Lena: lo spirito del popolo ci ha portati dalla caverna a questa collina di pietra. Ora siamo un regno. Da dove cominciamo a governarlo?",
        ["Alza le mura della città", "Invia ambasciate ai vicini", "Erigi il tempio del regno"],
    ),
    "d_corte_02_voce_bosco": (
        "Sereth: un inviato straniero ha detto una frase che gela il sangue - un volto senza nome, una voce sotto la pietra. Iove giura di averla già sentita. Come reagiamo?",
        ["Dai ascolto alla Voce", "Trattala come una semplice diceria", "Manda esploratori a verificare"],
    ),
    "d_corte_03_fondazione": (
        "Karro: il popolo guarda al nuovo consiglio e chiede su cosa fonderemo il regno. La prima pietra dirà chi siamo. Su cosa la posiamo?",
        ["Fonda il regno sulle mura", "Fondalo sulla piazza e sulla gente", "Fondalo sul sapere"],
    ),
    "d_corte_04_impero": (
        "Sereth: l'Impero del Sole pretende un tributo. È potente ma decadente, e ci guarda come preda facile. Cosa rispondiamo a est?",
        ["Paga il tributo per ora", "Rifiuta e mostra le armi", "Infiltra la loro corte"],
    ),
    "d_corte_05_lega": (
        "Vorrik: la Lega delle Coste a ovest non vuole guerra, vuole guadagno - mercanti, navi, oro. Possiamo farne alleati o vacche da mungere. Cosa decidiamo?",
        ["Stringi un'alleanza commerciale", "Costruisci un porto comune", "Imponi dazi con la flotta armata"],
    ),
    "d_corte_06_conflitto": (
        "Karro: curia e popolo si scontrano nelle piazze per il sapere di Iove. C'è chi vuole bruciarne i libri e chi morirebbe per difenderli. Il regno trema. Da che parte stiamo?",
        ["Proteggi l'Alchimista e i suoi libri", "Imponi l'ordine della curia", "Reprimi i tumulti nel sangue"],
    ),
    "d_corte_07_tempio": (
        "Iove: hanno trovato un tempio ai margini della città. Nessuno l'ha costruito, nessuno ricorda quando sia apparso - ed è identico all'Idolo del Fuoco della caverna. Cosa ne facciamo?",
        ["Studia il tempio e i suoi segreti", "Consacralo all'ordine del regno", "Demoliscilo e ricostruiscilo a modo nostro"],
    ),
    "d_corte_08_destino": (
        "Karro: il regno è al bivio. L'Impero del Sole vacilla, la Lega osserva, le macchine di Lena fremono. La prossima mossa deciderà che era lasceremo dietro di noi. Quale strada prendiamo?",
        ["Marcia contro l'Impero", "Media una pace duratura", "Avvia la grande fonderia"],
    ),
    "d_corte_09_convergenza": (
        "Iove: la presenza che ci segue da ere è qui, nel tempio che nessuno ha costruito. Chiede solo di essere accolta. Cosa diventa il popolo dello spirito?",
        ["Accogli la Voce dentro di voi", "Rifiutala, resta umano", "Sigillala con la forza"],
    ),
    "d_idolo_01_erigi": (
        "Aru: Costruzione e Popolo sono pronti, la pietra attende le mani di Tev. Diamo al popolo il suo primo simbolo eterno?",
        ["Erigi l'Idolo del Fuoco"],
    ),
}


def rewrite(path):
    t = open(path, encoding="utf-8").read()
    did = os.path.basename(path)[:-5]
    if did not in DATA:
        return False
    prompt, labels = DATA[did]

    n_opt = len(re.findall(r'label_text = ".*?"', t, flags=re.S))
    if n_opt != len(labels):
        raise SystemExit("%s: %d opzioni nel file ma %d label fornite" % (did, n_opt, len(labels)))

    # replace prompt
    t = re.sub(r'testo_consigliere = ".*?"',
               lambda _m: 'testo_consigliere = "%s"' % prompt, t, count=1, flags=re.S)

    # replace each label_text occurrence in order
    it = iter(labels)
    t = re.sub(r'label_text = ".*?"',
               lambda _m: 'label_text = "%s"' % next(it), t, flags=re.S)

    open(path, "w", encoding="utf-8").write(t)
    return True


if __name__ == "__main__":
    n = 0
    for f in sorted(glob.glob("data/decisions/*.tres")):
        if rewrite(f):
            n += 1
    print("rewritten %d decisions" % n)
