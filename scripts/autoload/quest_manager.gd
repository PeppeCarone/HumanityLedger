extends Node

var tutte_le_quest: Array[Resource] = []
var quest_attive: Array[Resource] = []
var quest_chiave_corrente: Resource = null

signal quest_avviata(quest: Resource)
signal quest_completata(quest: Resource)
signal quest_chiave_completata(quest: Resource)


func _ready() -> void:
	carica_quest()


func carica_quest() -> void:
	tutte_le_quest.clear()
	var dir: DirAccess = DirAccess.open("res://data/quests")
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			var res: Resource = load("res://data/quests/" + name)
			if res != null:
				tutte_le_quest.append(res)
		name = dir.get_next()
	dir.list_dir_end()


func quest_disponibili_per_era(era: int) -> Array[Resource]:
	var out: Array[Resource] = []
	for q in tutte_le_quest:
		if q.get("era") == era and not GameState.quest_e_completata(q.get("id")):
			out.append(q)
	return out


func avvia_quest(quest: Resource) -> void:
	if quest in quest_attive:
		return
	quest_attive.append(quest)
	if quest.get("tipo") == "chiave":
		quest_chiave_corrente = quest
	quest_avviata.emit(quest)


func completa_quest(quest: Resource) -> void:
	if quest not in quest_attive:
		return
	quest_attive.erase(quest)
	GameState.segna_quest_completata(quest.get("id"))
	if quest == quest_chiave_corrente:
		quest_chiave_corrente = null
		quest_chiave_completata.emit(quest)
	quest_completata.emit(quest)


func quest_visibili_nel_log() -> Array[Resource]:
	var out: Array[Resource] = []
	for q in quest_attive:
		if q.get("visibile_nel_log") == true:
			out.append(q)
	return out
