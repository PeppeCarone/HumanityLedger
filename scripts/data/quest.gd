class_name Quest
extends Resource

@export var id: String
@export var titolo: String
@export var era: int = 1
@export var tipo: String = "principale"
@export var precondizioni_flag: Array[String] = []
@export var precondizioni_stat: Dictionary = {}
@export var passi: Array[Decision] = []
@export var effetto_completamento: Effect
@export var flag_di_completamento: String
@export var visibile_nel_log: bool = true
@export var descrizione_log: String


func soddisfa_precondizioni() -> bool:
	for flag in precondizioni_flag:
		if not GameState.has_flag(flag):
			return false
	for stat_name in precondizioni_stat.keys():
		if GameState.get_stat(stat_name) < int(precondizioni_stat[stat_name]):
			return false
	return true
