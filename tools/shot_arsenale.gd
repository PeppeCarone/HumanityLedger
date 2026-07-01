extends Node
# Harness dedicato (Docs/20): verifica a schermo l'ARSENALE del villaggio.
# Eseguire con contesto di rendering (NON --headless), come scena principale:
#   godot --path . res://tools/shot_arsenale.tscn
# Scatti in tools/_preview/. Si chiude da solo.

const OUT := "res://tools/_preview/"


func _ready() -> void:
	await _run()
	get_tree().quit()


func _shot(path: String, name: String, setup: Callable = Callable(), post: Callable = Callable(), attesa: float = 0.6) -> void:
	var inst: Node = load(path).instantiate()
	if setup.is_valid():
		setup.call(inst)
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	if post.is_valid():
		post.call(inst)
	await get_tree().create_timer(attesa).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("SHOT ", name, " ", img.get_size())
	inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _run() -> void:
	# 1) Pannello edificio: la riga "Assedio: ..." mostra il payoff difesa (Palizzata = muro).
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 60
	GameState.risorse = 50
	GameState.edifici_livelli = {"1_5": 2}
	await _shot("res://scenes/main.tscn", "arsenale_edificio", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_edificio(5), 0.9)

	# 2) Card pre-Assedio "Il tuo villaggio ti arma" (valori iniettati per verificare il rendering).
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	await _shot("res://scenes/main.tscn", "arsenale_card", Callable(), func(inst: Node) -> void:
		inst._arsenale_pending = {"hp": 42, "monete": 15, "truppe": 2, "livello": 2, "scorte": 12}
		inst._mostra_card_assedio(1), 1.1)

	# 3) Percorso VERO: villaggio maxato -> _avvia_assedio -> _calcola_arsenale -> milizia + HP.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 55
	GameState.militare = 55
	GameState.risorse = 60
	GameState.edifici_livelli = {"1_0": 3, "1_1": 3, "1_2": 3, "1_3": 3, "1_4": 3, "1_5": 3}
	await _shot("res://scenes/main.tscn", "arsenale_siege", Callable(), func(inst: Node) -> void:
		inst._avvia_assedio(1), 3.6)

	# 4) BOSS FINALE — card intro "L'ULTIMO DIO" (+ riepilogo arsenale Era 2).
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.set_flag("era2_completata", true)
	GameState.set_flag("era2_assedio_fatto", true)
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 60
	GameState.militare = 55
	GameState.risorse = 60
	GameState.edifici_livelli = {"2_0": 3, "2_1": 3, "2_2": 3, "2_3": 3, "2_4": 3, "2_5": 3}
	await _shot("res://scenes/main.tscn", "finale_card", Callable(), func(inst: Node) -> void:
		inst._avvia_boss_finale(), 1.4)

	# 5) BOSS FINALE — il duello: L'Ultimo Dio in campo (arte-placeholder finché non c'è il PNG).
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.set_flag("era2_completata", true)
	GameState.set_flag("era2_assedio_fatto", true)
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 60
	GameState.militare = 60
	GameState.scienza = 55
	GameState.risorse = 60
	GameState.edifici_livelli = {"2_0": 3, "2_1": 3, "2_2": 3, "2_3": 3, "2_4": 3, "2_5": 3}
	await _shot("res://scenes/main.tscn", "finale_duel", Callable(), func(inst: Node) -> void:
		inst._avvia_boss_finale(), 6.2)

	# 6) TOOLTIP edificio (hover): warp del mouse sulla Palizzata (slot 5) + attesa del delay.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 60
	GameState.edifici_livelli = {"1_5": 2}
	await _shot("res://scenes/main.tscn", "tooltip_edificio", Callable(), func(inst: Node) -> void:
		var v: Node = inst.village
		if v != null and v._edifici_sprite.size() > 5:
			var tr: Control = v._edifici_sprite[5]
			Input.warp_mouse(tr.global_position + tr.size * 0.5), 1.4)

	# 7) EPILOGO "La Soglia" (verifica soglia.png dietro il testo).
	GameState.reset_run()
	GameState.era_corrente = 2
	await _shot("res://scenes/main.tscn", "finale_epilogo", Callable(), func(inst: Node) -> void:
		inst._mostra_epilogo_soglia(true), 1.2)
