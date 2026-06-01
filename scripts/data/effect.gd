class_name Effect
extends Resource

@export var stat_delta: Dictionary = {}
@export var set_flags: Dictionary = {}
@export var unlock_lore: Array[String] = []
@export var add_decisione_chiave: String = ""
@export var add_to_log: String = ""
@export var rapporti_civilta: Dictionary = {}
@export var popolazione_delta: int = 0


func get_stat_delta() -> Dictionary:
	return stat_delta
