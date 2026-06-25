extends Node
# Screenshot harness: run with a rendering context (NOT --headless), as main scene.
# Captures menu, era1, era2 and ending into tools/_preview/.

const OUT := "res://tools/_preview/"


func _ready() -> void:
	await _run()


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
	GameState.reset_run()
	await _shot("res://scenes/main_menu.tscn", "shot_menu")
	await _shot("res://scenes/ui/options_menu.tscn", "shot_opzioni", Callable(), Callable(), 0.6)
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	await _shot("res://scenes/main.tscn", "shot_era1", Callable(), func(inst: Node) -> void:
		if inst.village != null:
			inst.village.applica_conseguenza("alleanza"))
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	await _shot("res://scenes/main.tscn", "shot_era1_campo")
	# Villaggio migliorabile: alcuni edifici a livello 2-3 (stelle + scala crescente).
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	GameState.edifici_livelli = {"1_0": 3, "1_2": 2, "1_5": 2}
	await _shot("res://scenes/main.tscn", "shot_villaggio_upgrade")
	# Pannello di upgrade aperto su un edificio (Palizzata -> Militare).
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 60
	GameState.tesoro = 50
	await _shot("res://scenes/main.tscn", "shot_upgrade_panel", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_edificio(5), 0.9)
	# Villaggio con lotto vuoto: marker "+" costruibile (slot 4, a destra), senza pannello/FX.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	await _shot("res://scenes/main.tscn", "shot_villaggio_builder")
	# Lotto "costruisci qui" (slot vuoto) + pannello di costruzione.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 2)
	GameState.costruzione = 55
	GameState.tesoro = 40
	GameState.risorse = 80   # abbastanza per abilitare le opzioni (pulsanti attivi, non grigi)
	await _shot("res://scenes/main.tscn", "shot_build_panel", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_costruzione(2), 0.9)
	# Vista villaggio gestionale (tasto V): elenco edifici, produzione, upgrade in un posto.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 5)
	GameState.costruzione = 60
	GameState.tesoro = 50
	GameState.risorse = 40
	GameState.edifici_livelli = {"1_0": 3, "1_2": 2, "1_4": 2}
	await _shot("res://scenes/main.tscn", "shot_villaggio_panel", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_villaggio(), 0.9)
	# J15: bandierine degli alleati radicate ai margini del villaggio.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 5)
	GameState.rapporti_civilta = {"clan_bisonte": 4, "impero_sole": 3}
	await _shot("res://scenes/main.tscn", "shot_villaggio_alleati", Callable(), Callable(), 1.0)
	# Toast traguardo del villaggio.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	await _shot("res://scenes/main.tscn", "shot_traguardo", Callable(), func(inst: Node) -> void:
		inst._toast_traguardo("Il Borgo Cresce", "+12 Risorse"), 0.9)
	# Danno da catastrofe: un edificio migliorato crolla di un livello.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 5)
	GameState.edifici_livelli = {"1_2": 3, "1_4": 2}
	await _shot("res://scenes/main.tscn", "shot_danno", Callable(), func(inst: Node) -> void:
		var e: Effect = Effect.new()
		e.popolazione_delta = -10
		inst._check_danno_catastrofe(e), 1.1)
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
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.artefatto_equipaggiato = "occhio_dello_spirito"   # mostra gli hint-stat
	await _shot("res://scenes/main.tscn", "shot_era2_decision", Callable(), func(inst: Node) -> void:
		inst._apri_decisione())
	# Richiamo narrativo cross-era: scelta Era 1 citata su d_corte_04_impero.
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.set_flag("era2_atto1_completato", true)
	GameState.segna_quest_completata("q_corte_si_forma")
	GameState.registra_scelta("d_con_01_bisonte", "era1_orm")
	await _shot("res://scenes/main.tscn", "shot_richiamo", Callable(), func(inst: Node) -> void:
		inst._apri_decisione())
	GameState.reset_run()
	await _shot("res://scenes/main.tscn", "shot_evento", Callable(), func(inst: Node) -> void:
		inst._imposta_event_image("conflitto_religioso"))
	# Catastrofe Carestia (Era 2 Atto 2): forza la decisione e apri la vista.
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.set_flag("era2_atto1_completato", true)
	GameState.segna_quest_completata("q_corte_si_forma")
	await _shot("res://scenes/main.tscn", "shot_carestia", Callable(), func(inst: Node) -> void:
		inst.current_quest = QuestManager.quest_per_id("q_pressione_imperi")
		inst.current_step = 4
		inst._show_current_decision()
		inst._apri_decisione())
	var dec: Decision = load("res://data/decisions/d_caverna_05_inverno.tres") as Decision
	print("CHECK inverno illustrazione_id=", dec.illustrazione_id if dec else "NULL")
	var fin: Finale = load("res://data/finali/fine_prosperita.tres") as Finale
	var set_fin: Callable = func(inst: Node) -> void: inst.finale = fin
	await _shot("res://scenes/ending_screen.tscn", "shot_ending", set_fin, Callable(), 3.5)
	GameState.reset_run()
	var show_trans: Callable = func(inst: Node) -> void: inst._show_transizione_a_era2()
	await _shot("res://scenes/main.tscn", "shot_transizione", Callable(), show_trans, 3.2)
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
	# L'Assedio (Fase B): "le stat diventano l'esercito". Istanziato via script (niente
	# .tscn): 3 corsie, villaggio+HP a sinistra, 4 unita' scalate dalle stat, alleati/
	# ostili dai rapporti con le civilta'.
	GameState.reset_run()
	GameState.costruzione = 55
	GameState.militare = 60
	GameState.tesoro = 45
	GameState.scienza = 50
	GameState.spionaggio = 45
	GameState.rapporti_civilta["clan_bisonte"] = 4    # alleato -> truppa gratis
	GameState.rapporti_civilta["popolo_nebbie"] = -3  # ostile -> rinforza i nemici
	var siege: CanvasLayer = SiegeArena.new()
	siege.configura(1)
	get_tree().root.add_child(siege)
	siege.schiera_unita_test(0, "tiratore")     # corsia 0
	siege.schiera_unita_test(3, "bloccatore")   # corsia 1
	siege.schiera_unita_test(7, "sciamano")     # corsia 2
	siege.schiera_unita_test(8, "totem")        # corsia 2
	# Mandria mista per mostrare i nemici per-tipo (cinghiale/iena/orso) sparsi sul campo.
	siege.spawn_enemy_test("cinghiale", 0, 1500.0)
	siege.spawn_enemy_test("iena", 0, 1280.0)
	siege.spawn_enemy_test("orso", 1, 1420.0)
	siege.spawn_enemy_test("cinghiale", 1, 1180.0)
	siege.spawn_enemy_test("iena", 2, 1520.0)
	siege.spawn_enemy_test("orso", 2, 1320.0)
	await get_tree().create_timer(3.0).timeout
	var simg: Image = get_viewport().get_texture().get_image()
	simg.save_png(OUT + "shot_assedio.png")
	print("SHOT shot_assedio ", simg.get_size())
	siege.queue_free()
	await get_tree().process_frame
	# Truppe ASCESA (Lv5): verifica gli sprite elite + proporzioni.
	GameState.reset_run()
	GameState.costruzione = 60
	GameState.militare = 60
	GameState.scienza = 55
	var siegea: CanvasLayer = SiegeArena.new()
	siegea.configura(1)
	get_tree().root.add_child(siegea)
	siegea._livello = {"tiratore": 5, "bloccatore": 5, "sciamano": 5, "totem": 5}
	siegea.schiera_unita_test(0, "tiratore")
	siegea.schiera_unita_test(3, "bloccatore")
	siegea.schiera_unita_test(6, "sciamano")
	siegea.schiera_unita_test(8, "totem")
	await get_tree().create_timer(2.0).timeout
	var aimg: Image = get_viewport().get_texture().get_image()
	aimg.save_png(OUT + "shot_assedio_ascesa.png")
	print("SHOT shot_assedio_ascesa ", aimg.get_size())
	siegea.queue_free()
	await get_tree().process_frame
	# Assedio Fase C: il BOSS in campo (entrata + barra HP dedicata in alto).
	GameState.reset_run()
	GameState.costruzione = 55
	GameState.militare = 60
	GameState.scienza = 50
	GameState.legge = 40
	var siegeb: CanvasLayer = SiegeArena.new()
	siegeb.configura(1)
	get_tree().root.add_child(siegeb)
	siegeb.schiera_unita_test(0, "tiratore")
	siegeb.schiera_unita_test(4, "bloccatore")
	siegeb.schiera_unita_test(7, "totem")
	siegeb.spawn_enemy_test("orso", 0, 1350.0)
	siegeb.spawn_enemy_test("iena", 2, 1450.0)
	siegeb.spawn_boss_test(true)
	await get_tree().create_timer(0.65).timeout
	var bimg: Image = get_viewport().get_texture().get_image()
	bimg.save_png(OUT + "shot_assedio_boss.png")
	print("SHOT shot_assedio_boss ", bimg.get_size())
	siegeb.queue_free()
	await get_tree().process_frame
	# Assedio Boss 2.0 — CINEMATICA DI CAMBIO FASE (F4): letterbox + title-card "FASE II" + zoom.
	GameState.reset_run()
	GameState.costruzione = 55
	GameState.militare = 60
	GameState.scienza = 50
	var sieget: CanvasLayer = SiegeArena.new()
	sieget.configura(1)
	get_tree().root.add_child(sieget)
	sieget.schiera_unita_test(0, "tiratore")
	sieget.schiera_unita_test(4, "bloccatore")
	sieget.spawn_boss_test(true)
	sieget.spawn_enemy_test("cinghiale", 1, 1300.0)   # add che devono SPARIRE all'intermezzo
	sieget.spawn_enemy_test("iena", 2, 1180.0)
	sieget.spawn_enemy_test("orso", 0, 1420.0)
	await get_tree().create_timer(0.6, true, false, true).timeout
	if sieget._boss != null and is_instance_valid(sieget._boss):
		sieget._boss._trasformato = true   # crepe d'ember sul corpo
		sieget.intermezzo_fase(sieget._boss, 2)   # nemici spariscono + cinematica "FASE II"
	await get_tree().create_timer(0.9, true, false, true).timeout   # letterbox dentro + title visibile
	var timg: Image = get_viewport().get_texture().get_image()
	timg.save_png(OUT + "shot_assedio_trasforma.png")
	print("SHOT shot_assedio_trasforma ", timg.get_size())
	sieget.queue_free()
	await get_tree().process_frame
	# Assedio Era 2 (drago + set Era 2): verifica gli asset Era 2.
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.costruzione = 55
	GameState.militare = 60
	GameState.scienza = 50
	var siege2: CanvasLayer = SiegeArena.new()
	siege2.configura(2)
	get_tree().root.add_child(siege2)
	siege2.schiera_unita_test(0, "tiratore")
	siege2.schiera_unita_test(4, "bloccatore")
	siege2.schiera_unita_test(5, "sciamano")
	siege2.schiera_unita_test(8, "totem")
	siege2.spawn_enemy_test("predone", 0, 1480.0)
	siege2.spawn_enemy_test("scheletro", 0, 1280.0)
	siege2.spawn_enemy_test("minotauro", 2, 1420.0)
	siege2.spawn_enemy_test("golem", 1, 1520.0)
	siege2.spawn_boss_test(true)   # forza un'abilità: cattura il telegrafo del Drago (soffio/pioggia)
	await get_tree().create_timer(0.95).timeout
	var b2: Image = get_viewport().get_texture().get_image()
	b2.save_png(OUT + "shot_assedio_era2.png")
	print("SHOT shot_assedio_era2 ", b2.get_size())
	siege2.queue_free()
	await get_tree().process_frame
	# Assedio Fase F: schermata d'esito (qui "trionfo"; immacolata/fatica/sopraffatto variano).
	GameState.reset_run()
	var siegee: CanvasLayer = SiegeArena.new()
	siegee.configura(1)
	get_tree().root.add_child(siegee)
	await get_tree().process_frame
	siegee._mostra_esito("trionfo")
	await get_tree().create_timer(0.5).timeout
	var eimg: Image = get_viewport().get_texture().get_image()
	eimg.save_png(OUT + "shot_assedio_esito.png")
	print("SHOT shot_assedio_esito ", eimg.get_size())
	siegee.queue_free()
	await get_tree().process_frame
	# Ledger con artefatti misti: semina SOLO in memoria (niente save -> niente
	# scrittura del ledger.json reale). Per questo va tenuto come ultimo shot.
	GameState.reset_run()
	Ledger.artefatti_sbloccati.assign(["pietra_del_fuoco", "occhio_dello_spirito"])
	Ledger.artefatto_scelto = "occhio_dello_spirito"
	await _shot("res://scenes/ledger_screen.tscn", "shot_ledger")
	get_tree().quit()
