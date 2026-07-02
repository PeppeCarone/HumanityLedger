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
	img.convert(Image.FORMAT_RGB8)
	img.save_png(OUT + name + ".png")
	print("SHOT ", name, " ", img.get_size())
	inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _run() -> void:
	# AUDIT polish/post-fx: menu + schermata decisione (per vedere lo shader globale a schermo).
	GameState.reset_run()
	await _shot("res://scenes/main_menu.tscn", "audit_menu")
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	GameState.scienza = 9
	await _shot("res://scenes/main.tscn", "audit_decisione", Callable(), func(inst: Node) -> void:
		inst._apri_decisione(), 1.0)
	# Menu PROPRIO (2ยฐ load: l'intro s'รจ giร  vista -> static la salta).
	GameState.reset_run()
	await _shot("res://scenes/main_menu.tscn", "audit_menu2", Callable(), Callable(), 1.3)
	# Vista villaggio gestionale (overview: elenco edifici + produzione).
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 5)
	GameState.costruzione = 60
	GameState.risorse = 40
	GameState.edifici_livelli = {"1_0": 3, "1_2": 2, "1_4": 2}
	await _shot("res://scenes/main.tscn", "audit_village", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_villaggio(), 0.9)

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

	# 8) GIUDIZIO DIVINO: arena finale diretta + ultimate castata a mano → cattura sull'impatto.
	GameState.reset_run()
	GameState.era_corrente = 2
	var ar: SiegeArena = SiegeArena.new()
	ar.finale = true
	ar.configura(2)
	get_tree().root.add_child(ar)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in range(6):
		ar.schiera_unita_test(0, ["bloccatore", "tiratore", "totem"][i % 3])
	ar.boss_ultimate(2, 30)   # coroutine: telegrafo ~1.3s poi le colonne di luce
	await get_tree().create_timer(1.52).timeout
	var gimg: Image = get_viewport().get_texture().get_image()
	gimg.convert(Image.FORMAT_RGB8)
	gimg.save_png(OUT + "finale_giudizio.png")
	print("SHOT finale_giudizio ", gimg.get_size())
	ar.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	# 9) LV5: ultimate VISIBILI (callout col nome + FX dedicato) — cast forzato dei 4 tipi.
	GameState.reset_run()
	GameState.militare = 50
	GameState.costruzione = 50
	GameState.scienza = 50
	GameState.spionaggio = 40
	var ar2: SiegeArena = SiegeArena.new()
	ar2.configura(1)
	get_tree().root.add_child(ar2)
	await get_tree().process_frame
	await get_tree().process_frame
	var unita: Array = []
	for t2 in ["tiratore", "bloccatore", "sciamano", "totem"]:
		ar2._livello[t2] = 5
		unita.append(ar2._piazza(t2, false))
	for i in range(5):
		ar2.spawn_enemy_test("orso", i, 860.0 + 50.0 * float(i))
	await get_tree().create_timer(0.7).timeout   # raggiungono il posto in formazione
	for u in unita:
		if u != null and is_instance_valid(u):
			u._cast_ultimate()
	await get_tree().create_timer(0.30).timeout
	var uimg: Image = get_viewport().get_texture().get_image()
	uimg.convert(Image.FORMAT_RGB8)
	uimg.save_png(OUT + "lv5_ultimate.png")
	print("SHOT lv5_ultimate ", uimg.get_size())
	ar2.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	# 10) DUELLO FASE II — L'Idolo GIGANTE e immobile a destra, l'armata lo bersaglia da ovunque.
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.militare = 55
	GameState.costruzione = 50
	GameState.scienza = 50
	var ar3: SiegeArena = SiegeArena.new()
	ar3.finale = true
	ar3.configura(2)
	get_tree().root.add_child(ar3)
	await get_tree().process_frame
	await get_tree().process_frame
	for t3 in ["tiratore", "bloccatore", "totem", "sciamano", "tiratore"]:
		ar3.schiera_unita_test(0, t3)
	await get_tree().create_timer(2.7).timeout   # pausa 1.8 + spawn: il Dio è in campo
	if ar3._boss != null and is_instance_valid(ar3._boss):
		ar3._boss._cambia_fase()                  # forza la FASE II
	await get_tree().create_timer(2.8).timeout   # trasformazione + Idolo eretto a destra
	var g2: Image = get_viewport().get_texture().get_image()
	g2.convert(Image.FORMAT_RGB8)
	g2.save_png(OUT + "finale_fase2.png")
	print("SHOT finale_fase2 ", g2.get_size())
	ar3.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
