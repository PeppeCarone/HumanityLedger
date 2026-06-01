class_name Catastrofe
extends Resource

@export var id: String
@export var titolo: String
@export var illustrazione: Texture2D
@export var trigger_stat_min: Dictionary = {}
@export var trigger_stat_max: Dictionary = {}
@export var trigger_flag_richiesti: Array[String] = []
@export var era: int = 0
@export var decisione_iniziale: Decision
@export var decisioni_followup: Array[Decision] = []


func puo_innescarsi() -> bool:
	if era != 0 and era != GameState.era_corrente:
		return false
	for stat_name in trigger_stat_min.keys():
		if GameState.get_stat(stat_name) < int(trigger_stat_min[stat_name]):
			return false
	for stat_name in trigger_stat_max.keys():
		if GameState.get_stat(stat_name) > int(trigger_stat_max[stat_name]):
			return false
	for flag in trigger_flag_richiesti:
		if not GameState.has_flag(flag):
			return false
	return true
