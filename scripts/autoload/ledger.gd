extends Node

const LEDGER_PATH: String = "user://ledger.json"
const SAVE_VERSION: int = 1

var lore_sbloccata: Array[String] = []
var artefatti_sbloccati: Array[String] = []
var eventi_sbloccati: Array[String] = []
# Artefatto scelto per le prossime run (meta-persistente, applicato da reset_run).
var artefatto_scelto: String = ""
# Nuovo Ciclo+ ("Eone"): tier di rigiocabilità meta-persistente. 0 = prima vita.
# Sale solo quando il giocatore sceglie "Nuovo Ciclo+" dall'epilogo. Distinto da
# `ciclo_luce` (giorno/notte). Scala minaccia/fragilità dell'Assedio e nomina un
# "mutatore" tematico, così ogni ciclo è una sfida riconoscibilmente diversa.
var eone: int = 0

# Mutatori-sfida: nome+descrizione mostrati al giocatore per l'Eone corrente.
# Onesti rispetto allo scaling reale (più minaccia, mura più fragili, boss più duri).
const MUTATORI: Array[Dictionary] = [
	{"nome": "Memoria del Crollo", "descr": "L'orda ricorda ogni assedio: nemici più numerosi e tenaci."},
	{"nome": "Fame Antica", "descr": "Le mura portano le crepe dei cicli passati: il villaggio cede prima."},
	{"nome": "Ira degli Spiriti", "descr": "I custodi nemici colpiscono più duro a ogni ondata."},
	{"nome": "Eco Senza Fine", "descr": "Ogni boss ritorna più potente di quello che fu."},
	{"nome": "Il Peso dei Secoli", "descr": "La minaccia non conosce tregua: tutto è portato all'estremo."},
]

signal lore_unlocked(id: String)
signal artefatto_unlocked(id: String)
signal evento_unlocked(id: String)


func _ready() -> void:
	load_ledger()


func unlock_lore(id: String) -> void:
	if id in lore_sbloccata:
		return
	lore_sbloccata.append(id)
	lore_unlocked.emit(id)
	save()


func unlock_artefatto(id: String) -> void:
	if id in artefatti_sbloccati:
		return
	artefatti_sbloccati.append(id)
	artefatto_unlocked.emit(id)
	save()


func unlock_evento(id: String) -> void:
	if id in eventi_sbloccati:
		return
	eventi_sbloccati.append(id)
	evento_unlocked.emit(id)
	save()


func scegli_artefatto(id: String) -> void:
	# Toggle: ri-cliccare l'artefatto scelto lo rimuove.
	if id != "" and not is_artefatto_unlocked(id):
		return
	artefatto_scelto = "" if artefatto_scelto == id else id
	save()


func is_lore_unlocked(id: String) -> bool:
	return id in lore_sbloccata


func is_artefatto_unlocked(id: String) -> bool:
	return id in artefatti_sbloccati


func is_evento_disponibile(id: String) -> bool:
	return id in eventi_sbloccati


# --- Nuovo Ciclo+ ("Eone") --------------------------------------------------

# Sale di un tier (chiamato dall'epilogo quando si sceglie "Nuovo Ciclo+").
func avanza_eone() -> void:
	eone += 1
	save()


func in_eone() -> bool:
	return eone > 0


# Etichetta tematica del tier dato (1 -> "Eone I"). 0 -> "" (prima vita).
func eone_nome(tier: int = -1) -> String:
	var t: int = eone if tier < 0 else tier
	if t <= 0:
		return ""
	return "Eone %s" % _romano(t)


# Moltiplicatore di minaccia dell'Assedio dovuto all'Eone (compone con la difficoltà).
func ng_minaccia_mult() -> float:
	return minf(1.0 + 0.15 * float(eone), 2.0)


# Moltiplicatore HP villaggio dovuto all'Eone (mura più fragili salendo). Cap a 0.75.
func ng_villaggio_mult() -> float:
	return maxf(1.0 - 0.05 * float(clampi(eone, 0, 5)), 0.75)


func mutatore_nome() -> String:
	if eone <= 0:
		return ""
	return MUTATORI[clampi(eone - 1, 0, MUTATORI.size() - 1)]["nome"]


func mutatore_descr() -> String:
	if eone <= 0:
		return ""
	return MUTATORI[clampi(eone - 1, 0, MUTATORI.size() - 1)]["descr"]


func _romano(n: int) -> String:
	const VAL: Array[int] = [10, 9, 5, 4, 1]
	const SYM: Array[String] = ["X", "IX", "V", "IV", "I"]
	if n <= 0:
		return str(n)
	if n > 39:
		return str(n)   # oltre il flavor: numero arabo
	var out: String = ""
	var r: int = n
	for i in VAL.size():
		while r >= VAL[i]:
			out += SYM[i]
			r -= VAL[i]
	return out


func save() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"lore_sbloccata": lore_sbloccata,
		"artefatti_sbloccati": artefatti_sbloccati,
		"eventi_sbloccati": eventi_sbloccati,
		"artefatto_scelto": artefatto_scelto,
		"eone": eone,
	}
	var file: FileAccess = FileAccess.open(LEDGER_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Impossibile scrivere ledger: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_ledger() -> void:
	if not FileAccess.file_exists(LEDGER_PATH):
		return
	var file: FileAccess = FileAccess.open(LEDGER_PATH, FileAccess.READ)
	if file == null:
		push_error("Impossibile leggere ledger: %s" % FileAccess.get_open_error())
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("Ledger corrotto, ignorato")
		return
	var data: Dictionary = parsed
	lore_sbloccata.assign(data.get("lore_sbloccata", []))
	artefatti_sbloccati.assign(data.get("artefatti_sbloccati", []))
	eventi_sbloccati.assign(data.get("eventi_sbloccati", []))
	artefatto_scelto = data.get("artefatto_scelto", "")
	if artefatto_scelto != "" and not is_artefatto_unlocked(artefatto_scelto):
		artefatto_scelto = ""
	eone = maxi(0, int(data.get("eone", 0)))


func reset_ledger() -> void:
	lore_sbloccata.clear()
	artefatti_sbloccati.clear()
	eventi_sbloccati.clear()
	artefatto_scelto = ""
	eone = 0
	if FileAccess.file_exists(LEDGER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEDGER_PATH))
