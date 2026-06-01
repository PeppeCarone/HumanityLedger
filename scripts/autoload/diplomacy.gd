extends Node

var civilta: Dictionary = {}

signal ambasciatore_arriva(civ_id: String)
signal rapporto_changed(civ_id: String, valore_vecchio: int, valore_nuovo: int)


func registra_civilta(civ_id: String, dati: Dictionary) -> void:
	civilta[civ_id] = dati
	if not GameState.rapporti_civilta.has(civ_id):
		GameState.rapporti_civilta[civ_id] = dati.get("rapporto_iniziale", 0)


func get_rapporto(civ_id: String) -> int:
	return GameState.rapporti_civilta.get(civ_id, 0)


func modifica_rapporto(civ_id: String, delta: int) -> void:
	var vecchio: int = get_rapporto(civ_id)
	GameState.modifica_rapporto_civilta(civ_id, delta)
	var nuovo: int = get_rapporto(civ_id)
	if vecchio != nuovo:
		rapporto_changed.emit(civ_id, vecchio, nuovo)


func presenta_ambasciatore(civ_id: String) -> void:
	ambasciatore_arriva.emit(civ_id)


func civilta_per_era(era: int) -> Array[String]:
	var out: Array[String] = []
	for civ_id in civilta.keys():
		var dati: Dictionary = civilta[civ_id]
		if dati.get("era", 0) == era:
			out.append(civ_id)
	return out


func reset() -> void:
	civilta.clear()
