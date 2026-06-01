class_name Finale
extends Resource

@export var id: String
@export var nome: String
@export var illustrazione: Texture2D
@export var testo: String
@export var musica: AudioStream
@export var condizioni_stat: Dictionary = {}
@export var decisioni_chiave_richieste: Array[String] = []
@export var decisioni_chiave_escludenti: Array[String] = []
@export var priorita: int = 0


func match_score() -> int:
	for stat_name in condizioni_stat.keys():
		if GameState.get_stat(stat_name) < int(condizioni_stat[stat_name]):
			return -1
	for dc in decisioni_chiave_richieste:
		if dc not in GameState.decisioni_chiave:
			return -1
	for dc in decisioni_chiave_escludenti:
		if dc in GameState.decisioni_chiave:
			return -1
	var score: int = priorita
	for stat_name in condizioni_stat.keys():
		score += GameState.get_stat(stat_name)
	score += decisioni_chiave_richieste.size() * 50
	return score
