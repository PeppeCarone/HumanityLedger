extends Node
# DEBUG: parte DRITTA al boss fight, per testarlo velocemente.
# Lancia con:  godot --path . tools/boss_arena.tscn
# In gioco:  premi 1 = Colosso (Era 1)   ·   premi 2 = Drago (Era 2)   ·   R = ricomincia

var _siege: CanvasLayer = null
var _era: int = 1

func _ready() -> void:
	_avvia(1)

func _avvia(era: int) -> void:
	_era = era
	if _siege != null and is_instance_valid(_siege):
		_siege.queue_free()
	GameState.reset_run()
	GameState.era_corrente = era
	GameState.costruzione = 62
	GameState.militare = 66
	GameState.scienza = 58
	GameState.tesoro = 55
	GameState.spionaggio = 52
	GameState.legge = 45
	GameState.popolo = 52
	GameState.diplomazia = 45
	_siege = SiegeArena.new()
	_siege.configura(era)
	add_child(_siege)
	await get_tree().process_frame
	await get_tree().process_frame
	if _siege.has_method("debug_solo_boss"):
		_siege.debug_solo_boss()

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match (e as InputEventKey).keycode:
			KEY_1:
				_avvia(1)
			KEY_2:
				_avvia(2)
			KEY_R:
				_avvia(_era)
