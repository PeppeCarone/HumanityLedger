extends Node

const STAT_NAMES: Array[String] = [
	"militare", "tesoro", "diplomazia", "scienza",
	"legge", "spionaggio", "popolo", "costruzione"
]

const STAT_MIN: int = 0
const STAT_MAX: int = 100

const INITIAL_STAT_VALUE: int = 30
const INITIAL_POPOLAZIONE: int = 40

var militare: int = INITIAL_STAT_VALUE
var tesoro: int = INITIAL_STAT_VALUE
var diplomazia: int = INITIAL_STAT_VALUE
var scienza: int = INITIAL_STAT_VALUE
var legge: int = INITIAL_STAT_VALUE
var spionaggio: int = INITIAL_STAT_VALUE
var popolo: int = INITIAL_STAT_VALUE
var costruzione: int = INITIAL_STAT_VALUE

var popolazione: int = INITIAL_POPOLAZIONE

var era_corrente: int = 1
var atto_corrente: int = 1
var quest_completate: Array[String] = []
var flag_narrativi: Dictionary = {}
var decisioni_chiave: Array[String] = []
var rapporti_civilta: Dictionary = {}
var artefatto_equipaggiato: String = ""
var mystery_attiva: bool = false

const MYSTERY_SOGLIA: int = 2

signal stat_changed(nome: String, valore_vecchio: int, valore_nuovo: int)
signal flag_set(nome: String, valore: Variant)
signal era_advanced(nuova_era: int)
signal popolazione_changed(valore_vecchio: int, valore_nuovo: int)
signal mystery_attivata
signal rapporto_changed(civ_id: String, valore_vecchio: int, valore_nuovo: int)


func get_stat(nome: String) -> int:
	match nome:
		"militare": return militare
		"tesoro": return tesoro
		"diplomazia": return diplomazia
		"scienza": return scienza
		"legge": return legge
		"spionaggio": return spionaggio
		"popolo": return popolo
		"costruzione": return costruzione
		_:
			push_warning("Stat sconosciuta: %s" % nome)
			return 0


func stat_dominante() -> String:
	var migliore: String = STAT_NAMES[0]
	var valore_max: int = -1
	for nome in STAT_NAMES:
		var v: int = get_stat(nome)
		if v > valore_max:
			valore_max = v
			migliore = nome
	return migliore


func set_stat(nome: String, valore: int) -> void:
	var clamped: int = clampi(valore, STAT_MIN, STAT_MAX)
	var vecchio: int = get_stat(nome)
	if vecchio == clamped:
		return
	match nome:
		"militare": militare = clamped
		"tesoro": tesoro = clamped
		"diplomazia": diplomazia = clamped
		"scienza": scienza = clamped
		"legge": legge = clamped
		"spionaggio": spionaggio = clamped
		"popolo": popolo = clamped
		"costruzione": costruzione = clamped
		_:
			push_warning("Stat sconosciuta: %s" % nome)
			return
	stat_changed.emit(nome, vecchio, clamped)


func modifica_stat(nome: String, delta: int) -> void:
	set_stat(nome, get_stat(nome) + delta)


func modifica_popolazione(delta: int) -> void:
	var vecchio: int = popolazione
	popolazione = maxi(0, popolazione + delta)
	if vecchio != popolazione:
		popolazione_changed.emit(vecchio, popolazione)


func set_flag(nome: String, valore: Variant) -> void:
	flag_narrativi[nome] = valore
	flag_set.emit(nome, valore)


func has_flag(nome: String) -> bool:
	return flag_narrativi.has(nome) and flag_narrativi[nome] == true


func aggiungi_decisione_chiave(id: String) -> void:
	if id not in decisioni_chiave:
		decisioni_chiave.append(id)


func quest_e_completata(id: String) -> bool:
	return id in quest_completate


func segna_quest_completata(id: String) -> void:
	if id not in quest_completate:
		quest_completate.append(id)


func modifica_rapporto_civilta(civ_id: String, delta: int) -> void:
	var corrente: int = rapporti_civilta.get(civ_id, 0)
	var nuovo: int = clampi(corrente + delta, -100, 100)
	rapporti_civilta[civ_id] = nuovo
	if nuovo != corrente:
		rapporto_changed.emit(civ_id, corrente, nuovo)


func avanza_era() -> void:
	era_corrente += 1
	atto_corrente = 1
	era_advanced.emit(era_corrente)


func apply_effect(effetto: Resource) -> void:
	if effetto == null:
		return
	if effetto.has_method("get_stat_delta"):
		var deltas: Dictionary = effetto.get_stat_delta()
		for stat_name in deltas.keys():
			modifica_stat(stat_name, deltas[stat_name])
	if effetto.get("set_flags") != null:
		for flag in effetto.set_flags.keys():
			set_flag(flag, effetto.set_flags[flag])
	if effetto.get("add_decisione_chiave") != null and effetto.add_decisione_chiave != "":
		aggiungi_decisione_chiave(effetto.add_decisione_chiave)
	if effetto.get("rapporti_civilta") != null:
		for civ_id in effetto.rapporti_civilta.keys():
			modifica_rapporto_civilta(civ_id, effetto.rapporti_civilta[civ_id])
	if effetto.get("unlock_lore") != null:
		for lore_id in effetto.unlock_lore:
			Ledger.unlock_lore(lore_id)
	if effetto.get("unlock_eventi") != null:
		for evento_id in effetto.unlock_eventi:
			Ledger.unlock_evento(evento_id)
	if effetto.get("popolazione_delta") != null and effetto.popolazione_delta != 0:
		modifica_popolazione(effetto.popolazione_delta)
	valuta_mystery()


func mystery_punti() -> int:
	var punti: int = 0
	if "accolto_popolo_nebbie" in decisioni_chiave:
		punti += 1
	if has_flag("nebbie_osservati"):
		punti += 1
	if has_flag("sogno_accolto"):
		punti += 1
	if has_flag("ascolta_sogno_condiviso"):
		punti += 1
	if has_flag("pittura_ascoltata"):
		punti += 1
	if has_flag("voce_bosco_ascoltata"):
		punti += 1
	if has_flag("tempio_vuoto_studiato"):
		punti += 1
	if has_flag("canti_trascritti"):
		punti += 1
	if artefatto_equipaggiato == "lacrima_di_lyssa":
		punti += 1
	return punti


func valuta_mystery() -> void:
	if mystery_attiva:
		return
	if mystery_punti() >= MYSTERY_SOGLIA:
		mystery_attiva = true
		set_flag("mystery_attiva", true)
		mystery_attivata.emit()


func reset_run() -> void:
	for stat_name in STAT_NAMES:
		set_stat(stat_name, INITIAL_STAT_VALUE)
	var pop_vecchio: int = popolazione
	popolazione = INITIAL_POPOLAZIONE
	if pop_vecchio != popolazione:
		popolazione_changed.emit(pop_vecchio, popolazione)
	era_corrente = 1
	atto_corrente = 1
	quest_completate.clear()
	flag_narrativi.clear()
	decisioni_chiave.clear()
	rapporti_civilta.clear()
	artefatto_equipaggiato = ""
	mystery_attiva = false


func to_dict() -> Dictionary:
	return {
		"version": 1,
		"stats": {
			"militare": militare,
			"tesoro": tesoro,
			"diplomazia": diplomazia,
			"scienza": scienza,
			"legge": legge,
			"spionaggio": spionaggio,
			"popolo": popolo,
			"costruzione": costruzione,
		},
		"popolazione": popolazione,
		"era_corrente": era_corrente,
		"atto_corrente": atto_corrente,
		"quest_completate": quest_completate,
		"flag_narrativi": flag_narrativi,
		"decisioni_chiave": decisioni_chiave,
		"rapporti_civilta": rapporti_civilta,
		"artefatto_equipaggiato": artefatto_equipaggiato,
		"mystery_attiva": mystery_attiva,
	}


func from_dict(data: Dictionary) -> void:
	var stats: Dictionary = data.get("stats", {})
	for stat_name in STAT_NAMES:
		if stats.has(stat_name):
			set_stat(stat_name, stats[stat_name])
	popolazione = data.get("popolazione", INITIAL_POPOLAZIONE)
	era_corrente = data.get("era_corrente", 1)
	atto_corrente = data.get("atto_corrente", 1)
	quest_completate.assign(data.get("quest_completate", []))
	flag_narrativi = data.get("flag_narrativi", {})
	decisioni_chiave.assign(data.get("decisioni_chiave", []))
	rapporti_civilta = data.get("rapporti_civilta", {})
	artefatto_equipaggiato = data.get("artefatto_equipaggiato", "")
	mystery_attiva = data.get("mystery_attiva", false)
