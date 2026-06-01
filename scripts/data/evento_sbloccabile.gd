class_name EventoSbloccabile
extends Resource

@export var id: String
@export var nome_visibile: String = "???"
@export var nome_segreto: String
@export var precondizioni_lore: Array[String] = []
@export var precondizioni_artefatto_equipaggiato: String = ""
@export var decisioni: Array[Decision] = []


func e_disponibile() -> bool:
	for lore_id in precondizioni_lore:
		if not Ledger.is_lore_unlocked(lore_id):
			return false
	if precondizioni_artefatto_equipaggiato != "":
		if GameState.artefatto_equipaggiato != precondizioni_artefatto_equipaggiato:
			return false
	return true
