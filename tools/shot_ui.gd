extends Node
# Harness del pass di INTEGRITÀ VISIVA (Docs/24): scatta le schermate dove l'arte dipinta del
# UI kit (cornici, cartigli, barre) e le illustrazioni compaiono davvero, nei loro stati tipici
# (banner d'ondata al picco, boss ferito, toast al massimo, modali aperti).
# Eseguire con contesto di rendering (NON --headless), come scena principale:
#   godot --path . res://tools/shot_ui.tscn
# Scatti in tools/_preview/ui_*.png. Si chiude da solo.

const OUT := "res://tools/_preview/"


func _ready() -> void:
	# Numeri di RIFERIMENTO: neutralizza NG+/difficoltà dell'utente (solo in memoria).
	Ledger.eone = 0
	AudioManager._difficolta = 1
	await _run()
	get_tree().quit()


func _salva(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(OUT + name + ".png")
	print("SHOT ", name, " ", img.get_size())


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
	_salva(name)
	inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _assedio(era: int) -> SiegeArena:
	GameState.reset_run()
	GameState.era_corrente = era
	GameState.costruzione = 55
	GameState.militare = 60
	GameState.scienza = 50
	GameState.spionaggio = 50   # >= 45: il banner mostra anche la riga "Spionaggio"
	var s: SiegeArena = SiegeArena.new()
	s.configura(era)
	get_tree().root.add_child(s)
	return s


func _chiudi(n: Node) -> void:
	n.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _run() -> void:
	# Menu principale: il 1° load gioca l'intro (static), il 2° mostra il menu vero.
	GameState.reset_run()
	await _shot("res://scenes/main_menu.tscn", "ui_intro", Callable(), Callable(), 0.4)
	await _shot("res://scenes/main_menu.tscn", "ui_menu", Callable(), Callable(), 1.4)
	await _shot("res://scenes/ui/options_menu.tscn", "ui_opzioni")
	await _shot("res://scenes/ui/pause_menu.tscn", "ui_pausa")

	# Assedio: banner d'ondata al picco (titolo + riga Spionaggio) e barra villaggio.
	var s1: SiegeArena = _assedio(1)
	await get_tree().create_timer(0.3).timeout
	s1._ondata_idx = 0
	s1._mostra_banner(s1._testo_banner(s1._ondate[0]))
	await get_tree().create_timer(0.45).timeout
	_salva("ui_assedio_banner")
	await _chiudi(s1)

	# Boss ferito (60% HP, tenuta al 40%) con la barra dipinta; villaggio colpito (55%).
	var s2: SiegeArena = _assedio(1)
	s2.schiera_unita_test(0, "tiratore")
	s2.schiera_unita_test(4, "bloccatore")
	s2.spawn_boss_test(false)
	await get_tree().create_timer(0.9).timeout
	if s2._boss != null and is_instance_valid(s2._boss):
		s2._boss.hp = int(s2._boss.hp_max * 0.6)
		s2._aggiorna_boss_hp()
		s2._on_boss_stagger(0.4, false)
	s2.hp_villaggio = int(s2.hp_villaggio_max * 0.55)
	s2._aggiorna_hp()
	await get_tree().create_timer(0.2).timeout
	_salva("ui_assedio_boss")
	await _chiudi(s2)

	# Era 2: il Drago, barra quasi vuota (20%).
	var s3: SiegeArena = _assedio(2)
	s3.spawn_boss_test(false)
	await get_tree().create_timer(0.9).timeout
	if s3._boss != null and is_instance_valid(s3._boss):
		s3._boss.hp = int(s3._boss.hp_max * 0.2)
		s3._aggiorna_boss_hp()
	await get_tree().create_timer(0.2).timeout
	_salva("ui_assedio_boss_era2")
	await _chiudi(s3)

	# Esito dell'Assedio a lampo dorato finito.
	var s4: SiegeArena = _assedio(1)
	await get_tree().process_frame
	s4._mostra_esito("trionfo")
	await get_tree().create_timer(2.2).timeout
	_salva("ui_assedio_esito")
	await _chiudi(s4)

	# Toast traguardo al massimo dell'opacità.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 4)
	await _shot("res://scenes/main.tscn", "ui_traguardo", Callable(), func(inst: Node) -> void:
		inst._toast_traguardo("Il Borgo Cresce", "+12 Risorse"), 0.6)

	# Modali con la cornice ornata: upgrade, costruzione, villaggio.
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 6)
	GameState.costruzione = 60
	GameState.tesoro = 50
	await _shot("res://scenes/main.tscn", "ui_upgrade", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_edificio(5), 0.9)
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 2)
	GameState.costruzione = 55
	GameState.risorse = 80
	await _shot("res://scenes/main.tscn", "ui_build", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_costruzione(2), 0.9)
	GameState.reset_run()
	GameState.set_flag("villaggio_n", 5)
	GameState.costruzione = 60
	GameState.risorse = 40
	GameState.edifici_livelli = {"1_0": 3, "1_2": 2, "1_4": 2}
	await _shot("res://scenes/main.tscn", "ui_villaggio", Callable(), func(inst: Node) -> void:
		inst._apri_pannello_villaggio(), 0.9)

	# Decisioni con illustrazione d'evento (Era 2): carestia e incontro diplomatico.
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	GameState.set_flag("era2_atto1_completato", true)
	GameState.segna_quest_completata("q_corte_si_forma")
	await _shot("res://scenes/main.tscn", "ui_carestia", Callable(), func(inst: Node) -> void:
		inst.current_quest = QuestManager.quest_per_id("q_pressione_imperi")
		inst.current_step = 4
		inst._show_current_decision()
		inst._apri_decisione(), 0.9)
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.set_flag("era1_completata", true)
	await _shot("res://scenes/main.tscn", "ui_lena", Callable(), Callable(), 0.9)
