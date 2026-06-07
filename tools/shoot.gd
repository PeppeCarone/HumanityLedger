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
	await _shot("res://scenes/main.tscn", "shot_era1")
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	await _shot("res://scenes/main.tscn", "shot_era2")
	GameState.reset_run()
	await _shot("res://scenes/main.tscn", "shot_evento", Callable(), func(inst: Node) -> void:
		inst._imposta_event_image("conflitto_religioso"))
	var dec: Decision = load("res://data/decisions/d_caverna_05_inverno.tres") as Decision
	print("CHECK inverno illustrazione_id=", dec.illustrazione_id if dec else "NULL")
	var fin: Finale = load("res://data/finali/fine_prosperita.tres") as Finale
	await _shot("res://scenes/ending_screen.tscn", "shot_ending", func(inst: Node) -> void:
		inst.finale = fin)
	get_tree().quit()
