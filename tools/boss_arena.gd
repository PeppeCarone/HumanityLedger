extends Node
# DEBUG: parte DRITTA al boss fight, per testarlo velocemente senza giocare tutta la partita.
# Lancia con:  godot --path . tools/boss_arena.tscn
# (Cambia `configura(1)` in `configura(2)` per testare il Drago dell'Era 2.)

func _ready() -> void:
	GameState.reset_run()
	GameState.costruzione = 62
	GameState.militare = 66
	GameState.scienza = 58
	GameState.tesoro = 55
	GameState.spionaggio = 52
	GameState.legge = 45
	GameState.popolo = 52
	GameState.diplomazia = 45
	var siege: CanvasLayer = SiegeArena.new()
	siege.configura(1)
	add_child(siege)
	await get_tree().process_frame
	await get_tree().process_frame
	if siege.has_method("debug_solo_boss"):
		siege.debug_solo_boss()
