extends Node
# Screenshot harness: run with a rendering context (NOT --headless), as main scene.
# Captures menu, era1, era2 and ending into tools/_preview/.

const OUT := "res://tools/_preview/"


func _ready() -> void:
	await _run()


func _shot(path: String, name: String, setup: Callable = Callable(), post: Callable = Callable()) -> void:
	var inst: Node = load(path).instantiate()
	if setup.is_valid():
		setup.call(inst)
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	if post.is_valid():
		post.call(inst)
	await get_tree().create_timer(0.6).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("SHOT ", name, " ", img.get_size())
	inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _run() -> void:
	GameState.reset_run()
	await _shot("res://scenes/main_menu.tscn", "shot_menu")
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	await _shot("res://scenes/main.tscn", "shot_era1", Callable(), func(inst: Node) -> void:
		if inst.village != null:
			inst.village.applica_conseguenza("alleanza"))
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	GameState.scienza = 9   # sotto il prereq di Progetto Scientifico (15): opzione bloccata
	await _shot("res://scenes/main.tscn", "shot_era1_decision", Callable(), func(inst: Node) -> void:
		inst._apri_decisione())
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.rapporti_civilta = {"impero_sole": 3, "lega_coste": -2}
	await _shot("res://scenes/main.tscn", "shot_era2")
	GameState.reset_run()
	await _shot("res://scenes/main.tscn", "shot_evento", Callable(), func(inst: Node) -> void:
		inst._imposta_event_image("conflitto_religioso"))
	var dec: Decision = load("res://data/decisions/d_caverna_05_inverno.tres") as Decision
	print("CHECK inverno illustrazione_id=", dec.illustrazione_id if dec else "NULL")
	var fin: Finale = load("res://data/finali/fine_prosperita.tres") as Finale
	await _shot("res://scenes/ending_screen.tscn", "shot_ending", func(inst: Node) -> void:
		inst.finale = fin)
	# world map: serve configura() + attesa lunga per il crossfade/crescita insediamenti
	GameState.reset_run()
	GameState.militare = 70
	GameState.rapporti_civilta = {"impero_sole": -3, "lega_coste": 2}
	GameState.mystery_attiva = true
	var wm: Node = load("res://scenes/world_map.tscn").instantiate()
	wm.configura(1, 2, "Il mondo cambia", "Dal Paleolitico al Regno Mitico.")
	get_tree().root.add_child(wm)
	await get_tree().create_timer(5.5).timeout
	var wimg: Image = get_viewport().get_texture().get_image()
	wimg.save_png(OUT + "shot_worldmap.png")
	print("SHOT shot_worldmap ", wimg.get_size())
	wm.queue_free()
	await get_tree().process_frame
	get_tree().quit()
