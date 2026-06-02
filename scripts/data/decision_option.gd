class_name DecisionOption
extends Resource

@export var strategia: Strategia
@export var oggetto_drag: String = "icona_strategia"
@export var icona_drag: Texture2D
@export var label_text: String
@export var target_consigliere_id: String
@export var effetto: Effect
@export var feedback_testo: String


func is_disponibile() -> bool:
	if strategia == null:
		return true
	return strategia.soddisfa_prerequisiti()


func motivo_indisponibilita() -> String:
	if strategia == null:
		return ""
	for stat_name in strategia.prerequisiti_stat.keys():
		var richiesto: int = int(strategia.prerequisiti_stat[stat_name])
		var attuale: int = GameState.get_stat(stat_name)
		if attuale < richiesto:
			return "Serve %s %d (hai %d)" % [stat_name.capitalize(), richiesto, attuale]
	for flag in strategia.prerequisiti_flag:
		if not GameState.has_flag(flag):
			return "Manca evento: %s" % flag
	return ""
