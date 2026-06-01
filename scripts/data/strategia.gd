class_name Strategia
extends Resource

@export var id: String
@export var nome: String
@export var icona: Texture2D
@export var descrizione_breve: String
@export var prerequisiti_stat: Dictionary = {}
@export var prerequisiti_flag: Array[String] = []
@export var gesto_tipo: String = "icona_su_target"
@export var target_tag: String


func soddisfa_prerequisiti() -> bool:
	for stat_name in prerequisiti_stat.keys():
		if GameState.get_stat(stat_name) < int(prerequisiti_stat[stat_name]):
			return false
	for flag in prerequisiti_flag:
		if not GameState.has_flag(flag):
			return false
	return true
