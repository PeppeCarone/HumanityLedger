extends Node

const LEDGER_PATH: String = "user://ledger.json"
const SAVE_VERSION: int = 1

var lore_sbloccata: Array[String] = []
var artefatti_sbloccati: Array[String] = []
var eventi_sbloccati: Array[String] = []

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


func is_lore_unlocked(id: String) -> bool:
	return id in lore_sbloccata


func is_artefatto_unlocked(id: String) -> bool:
	return id in artefatti_sbloccati


func is_evento_disponibile(id: String) -> bool:
	return id in eventi_sbloccati


func save() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"lore_sbloccata": lore_sbloccata,
		"artefatti_sbloccati": artefatti_sbloccati,
		"eventi_sbloccati": eventi_sbloccati,
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


func reset_ledger() -> void:
	lore_sbloccata.clear()
	artefatti_sbloccati.clear()
	eventi_sbloccati.clear()
	if FileAccess.file_exists(LEDGER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEDGER_PATH))
