extends Node2D

const DROP_ZONE_SCENE: PackedScene = preload("res://scenes/ui/drop_zone.tscn")
const DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/ui/draggable_item.tscn")
const LEDGER_SCENE: PackedScene = preload("res://scenes/ledger_screen.tscn")
const ENDING_SCENE: PackedScene = preload("res://scenes/ending_screen.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const WORLD_MAP_SCENE: PackedScene = preload("res://scenes/world_map.tscn")
const CHARACTERS_DIR: String = "res://data/characters/"
const FINALI_DIR: String = "res://data/finali/"
const QUEST_SEQUENZE: Dictionary = {
	1: [
		"q_caverna_tutorial",
		"q_accampamento",
		"q_confronto",
		"q_idolo_del_fuoco",
	],
	2: [
		"q_corte_si_forma",
		"q_pressione_imperi",
		"q_scelta_finale",
	],
}
const CIV_LABELS: Dictionary = {
	"popolo_nebbie": "Popolo delle Nebbie",
	"clan_bisonte": "Clan del Bisonte",
	"impero_sole": "Impero del Sole",
	"lega_coste": "Lega delle Coste",
}
const COLOR_BG_ERA1: Color = Color(0.06, 0.05, 0.08, 0.55)
const COLOR_BG_ERA2: Color = Color(0.09, 0.07, 0.13, 0.5)
const COLOR_BG_MYSTERY: Color = Color(0.18, 0.05, 0.06, 0.6)
const FEEDBACK_PAUSE_SEC: float = 2.5
const STAT_TWEEN_DURATION: float = 0.55
const NARRATIVE_FADE_DURATION: float = 0.4

const COLOR_PROPOSER_NORMALE: Color = Color.WHITE
const COLOR_PROPOSER_CATASTROFE: Color = Color(0.6, 0.8, 1.0)
const COLOR_PROPOSER_SVOLTA: Color = Color(1.0, 0.85, 0.5)
const COLOR_PROPOSER_MISTERO: Color = Color(0.78, 0.6, 1.0)

# colori distinti per accoppiare ogni opzione al consigliere bersaglio (card <-> zona)
const ACCENT_PALETTE: Array[Color] = [
	Color(0.95, 0.78, 0.4),
	Color(0.5, 0.8, 0.95),
	Color(0.72, 0.92, 0.6),
	Color(0.95, 0.62, 0.56),
]

const PREFISSO_TIPO: Dictionary = {
	"catastrofe": "CATASTROFE — ",
	"svolta": "SVOLTA — ",
	"incontro": "INCONTRO — ",
	"mistero": "MISTERO — ",
}

const STAT_LABELS: Dictionary = {
	"militare": "Militare",
	"tesoro": "Tesoro",
	"diplomazia": "Diplomazia",
	"scienza": "Scienza",
	"legge": "Legge",
	"spionaggio": "Spionaggio",
	"popolo": "Popolo",
	"costruzione": "Costruzione",
}

const STAT_ICON_DIR: String = "res://Assets/art/stats/"
const BG_ERA1: String = "res://Assets/art/backgrounds/era1_caverna.png"
const BG_ERA2: String = "res://Assets/art/backgrounds/era2_citta.png"

@onready var scene_bg: TextureRect = $UI/SceneBg
@onready var hud_container: VBoxContainer = $UI/HUDPanel/VBoxContainer
@onready var consiglieri_row: HBoxContainer = $UI/ConsiglieriRow
@onready var decision_panel_row: HBoxContainer = $UI/DecisionPanel/HBoxContainer
@onready var narrative_label: Label = $UI/NarrativeLabel
@onready var help_label: Label = $UI/HelpLabel
@onready var proposer_portrait: TextureRect = $UI/ConsigliereProposer/HBox/PortraitProposer
@onready var proposer_name_label: Label = $UI/ConsigliereProposer/HBox/VBox/ProposerName
@onready var proposer_text_label: Label = $UI/ConsigliereProposer/HBox/VBox/ProposerText
@onready var event_image: TextureRect = $UI/ConsigliereProposer/HBox/EventImage

var quest_log_label: Label = null
var popolazione_label: Label = null
var stat_value_labels: Dictionary = {}
var rapporti_label: Label = null
var rapporti_box: VBoxContainer = null
var current_quest: Quest = null
var current_step: int = 0
var personaggi_db: Dictionary = {}
var _decision_accents: Dictionary = {}
var processing_drop: bool = false
var ledger_screen_instance: CanvasLayer = null
var ending_instance: CanvasLayer = null
var pause_instance: CanvasLayer = null
var stat_tweens: Dictionary = {}
var in_attesa_quest: bool = false
var in_transizione_era: bool = false


func _ready() -> void:
	help_label.text = "Scegli come rispondere: trascina un'opzione sul consigliere che la sostiene (si illumina di verde). Opzioni grigie = bloccate, passa il mouse per il requisito. L = Ledger, ESC = pausa."
	help_label.add_theme_font_size_override("font_size", 19)
	help_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	help_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	help_label.add_theme_constant_override("outline_size", 4)
	var titolo_font: Font = _font_titoli()
	if titolo_font != null:
		proposer_name_label.add_theme_font_override("font", titolo_font)
	_applica_cornici()
	_setup_hud()
	_load_personaggi()
	GameState.stat_changed.connect(_on_stat_changed)
	GameState.popolazione_changed.connect(_on_popolazione_changed)
	GameState.mystery_attivata.connect(_on_mystery_attivata)
	GameState.rapporto_changed.connect(_on_rapporto_changed)
	_start_era1()


func _font_titoli() -> Font:
	var path: String = "res://Assets/fonts/Cinzel.ttf"
	if not ResourceLoader.exists(path):
		return null
	var base: FontFile = load(path)
	var fv: FontVariation = FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": 600}
	return fv


func _applica_cornici() -> void:
	for node_path in ["UI/HUDPanel", "UI/ConsigliereProposer", "UI/DecisionPanel"]:
		var panel: Control = get_node_or_null(node_path)
		if panel == null:
			continue
		panel.add_theme_stylebox_override("panel", _stile_pannello())


func _stile_pannello() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.085, 0.07, 0.84)
	sb.border_color = Color(0.5, 0.38, 0.22, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	return sb


func _setup_hud() -> void:
	stat_value_labels.clear()
	for stat_name in GameState.STAT_NAMES:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = STAT_ICON_DIR + stat_name + ".png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		row.add_child(icon)
		var label: Label = Label.new()
		label.name = "Stat_" + stat_name
		label.text = "%s: %d" % [STAT_LABELS[stat_name], GameState.get_stat(stat_name)]
		label.add_theme_font_size_override("font_size", 20)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		hud_container.add_child(row)
		stat_value_labels[stat_name] = label
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	hud_container.add_child(spacer)
	popolazione_label = Label.new()
	popolazione_label.name = "Popolazione"
	popolazione_label.text = "Popolazione: %d" % GameState.popolazione
	popolazione_label.add_theme_font_size_override("font_size", 20)
	hud_container.add_child(popolazione_label)
	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	hud_container.add_child(spacer2)
	quest_log_label = Label.new()
	quest_log_label.name = "QuestLog"
	quest_log_label.add_theme_font_size_override("font_size", 18)
	quest_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_container.add_child(quest_log_label)
	var spacer3: Control = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 16)
	hud_container.add_child(spacer3)
	rapporti_label = Label.new()
	rapporti_label.name = "Rapporti"
	rapporti_label.add_theme_font_size_override("font_size", 16)
	rapporti_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_container.add_child(rapporti_label)
	rapporti_box = VBoxContainer.new()
	rapporti_box.name = "RapportiBox"
	rapporti_box.add_theme_constant_override("separation", 4)
	hud_container.add_child(rapporti_box)
	_refresh_rapporti()


func _load_personaggi() -> void:
	personaggi_db.clear()
	var dir: DirAccess = DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		push_error("Cartella personaggi non trovata: " + CHARACTERS_DIR)
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var res: Resource = load(CHARACTERS_DIR + fname)
			if res != null and res.get("id") != null and res.id != "":
				personaggi_db[res.id] = res
		fname = dir.get_next()
	dir.list_dir_end()


func _start_era1() -> void:
	QuestManager.quest_attive.clear()
	QuestManager.quest_chiave_corrente = null
	_aggiorna_sfondo_era()
	_avvia_prossima_quest()


func _aggiorna_sfondo_era() -> void:
	if scene_bg == null:
		return
	var path: String = BG_ERA2 if GameState.era_corrente >= 2 else BG_ERA1
	if ResourceLoader.exists(path):
		scene_bg.texture = load(path)
	AudioManager.play_music_id("era2" if GameState.era_corrente >= 2 else "era1")


func _avvia_prossima_quest() -> void:
	in_attesa_quest = false
	var q: Quest = _prossima_quest_disponibile()
	if q == null:
		if GameState.era_corrente == 1 and GameState.has_flag("era1_completata"):
			_show_transizione_a_era2()
		elif GameState.era_corrente == 2 and GameState.has_flag("era2_completata"):
			_show_ending()
		else:
			_show_attesa_quest()
		return
	current_quest = q
	QuestManager.avvia_quest(q)
	current_step = 0
	_show_current_decision()


func _quest_ids_era_corrente() -> Array:
	return QUEST_SEQUENZE.get(GameState.era_corrente, [])


func _prossima_quest_disponibile() -> Quest:
	for qid in _quest_ids_era_corrente():
		if GameState.quest_e_completata(qid):
			continue
		var q: Quest = QuestManager.quest_per_id(qid) as Quest
		if q != null and q.soddisfa_precondizioni():
			return q
	return null


func _quest_bloccata_da_stat() -> Quest:
	for qid in _quest_ids_era_corrente():
		if GameState.quest_e_completata(qid):
			continue
		var q: Quest = QuestManager.quest_per_id(qid) as Quest
		if q == null:
			continue
		var flag_ok: bool = true
		for flag in q.precondizioni_flag:
			if not GameState.has_flag(flag):
				flag_ok = false
				break
		if flag_ok and not q.soddisfa_precondizioni():
			return q
		return null
	return null


func _requisiti_testo(req: Dictionary) -> String:
	var parti: Array[String] = []
	for stat_name in req.keys():
		var etichetta: String = STAT_LABELS.get(stat_name, stat_name)
		parti.append("%s %d (hai %d)" % [etichetta, int(req[stat_name]), GameState.get_stat(stat_name)])
	return ", ".join(parti)


func _show_attesa_quest() -> void:
	in_attesa_quest = true
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	_show_narrative("")
	proposer_portrait.texture = null
	if event_image != null:
		event_image.visible = false
	proposer_name_label.modulate = COLOR_PROPOSER_NORMALE
	proposer_name_label.text = "Il consiglio attende"
	var bloccata: Quest = _quest_bloccata_da_stat()
	if bloccata != null:
		proposer_text_label.text = "%s\nServe ancora: %s" % [
			bloccata.descrizione_log, _requisiti_testo(bloccata.precondizioni_stat)
		]
		quest_log_label.text = "In attesa: %s\n(rafforza le stat richieste)" % bloccata.titolo
	else:
		proposer_text_label.text = "Le condizioni non sono ancora mature."
		quest_log_label.text = "In attesa"


func _show_transizione_a_era2() -> void:
	in_attesa_quest = false
	in_transizione_era = true
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	proposer_portrait.texture = null
	if event_image != null:
		event_image.visible = false
	proposer_name_label.modulate = COLOR_PROPOSER_SVOLTA
	proposer_name_label.text = "Fine dell'Era Paleolitica"
	proposer_text_label.text = "Le stagioni passano, le pietre crescono, i nomi cambiano. L'Idolo del Fuoco arde ancora, ma ora sopra un tempio. Il popolo è diventato un Regno Mitico."
	quest_log_label.text = "Era 1 completata.\nPremi INVIO per entrare nell'Era 2.\n(le stat vengono trasferite)"
	_show_narrative("Premi INVIO per attraversare le ere.")
	AudioManager.play_sfx("era_transition")


func _entra_era2() -> void:
	in_transizione_era = false
	GameState.avanza_era()
	_aggiorna_sfondo_era()
	var bg: ColorRect = $UI/Background
	if bg != null and not GameState.mystery_attiva:
		var t: Tween = create_tween()
		t.tween_property(bg, "color", COLOR_BG_ERA2, 1.0)
	_mostra_mappa_mondo(
		1, 2,
		"Il mondo cambia",
		"Dal Paleolitico al Regno Mitico: confini, regni e province prendono forma sulla terra."
	)


func _mostra_mappa_mondo(da_era: int, a_era: int, titolo: String, sottotitolo: String) -> void:
	var mappa: CanvasLayer = WORLD_MAP_SCENE.instantiate()
	mappa.configura(da_era, a_era, titolo, sottotitolo)
	mappa.chiuso.connect(_avvia_prossima_quest, CONNECT_ONE_SHOT)
	add_child(mappa)


func _show_ending() -> void:
	in_attesa_quest = false
	in_transizione_era = false
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	proposer_portrait.texture = null
	if event_image != null:
		event_image.visible = false
	proposer_name_label.modulate = COLOR_PROPOSER_NORMALE
	var finale: Finale = _valuta_finale()
	if finale != null:
		Ledger.unlock_lore("epilogo_" + finale.id)
		proposer_name_label.text = "Epilogo: %s" % finale.nome
		quest_log_label.text = "Era 2 completata.\nPremi R per ricominciare."
	else:
		proposer_name_label.text = "Epilogo"
	proposer_text_label.text = ""
	_show_narrative("Lo spirito ha preso la sua ultima decisione.")
	if ending_instance != null and is_instance_valid(ending_instance):
		ending_instance.queue_free()
	ending_instance = ENDING_SCENE.instantiate()
	ending_instance.finale = finale
	add_child(ending_instance)


func _valuta_finale() -> Finale:
	var finali: Array[Finale] = _carica_finali()
	if finali.is_empty():
		return null
	var migliore: Finale = null
	var miglior_punteggio: int = -1
	for f in finali:
		var s: int = f.match_score()
		if s > miglior_punteggio:
			miglior_punteggio = s
			migliore = f
	if migliore != null and miglior_punteggio >= 0:
		return migliore
	return _finale_fallback(finali)


func _carica_finali() -> Array[Finale]:
	var out: Array[Finale] = []
	var dir: DirAccess = DirAccess.open(FINALI_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var f: Finale = load(FINALI_DIR + fname) as Finale
			if f != null:
				out.append(f)
		fname = dir.get_next()
	dir.list_dir_end()
	return out


func _finale_fallback(finali: Array[Finale]) -> Finale:
	# Nessun finale soddisfa le condizioni: scegli quello la cui stat dominante
	# è più alta nel giocatore (escludendo il finale mystery, che richiede la scelta).
	var migliore: Finale = null
	var miglior_valore: int = -1
	for f in finali:
		if f.id == "fine_futura":
			continue
		var somma: int = 0
		for stat_name in f.condizioni_stat.keys():
			somma += GameState.get_stat(stat_name)
		if somma > miglior_valore:
			miglior_valore = somma
			migliore = f
	return migliore


func _show_current_decision() -> void:
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	_show_narrative("")
	if current_quest == null:
		return
	quest_log_label.text = "Quest: %s\n(passo %d/%d)" % [
		current_quest.titolo, current_step + 1, current_quest.passi.size()
	]
	if current_step >= current_quest.passi.size():
		_complete_quest()
		return
	var decision: Decision = current_quest.passi[current_step]
	if decision == null:
		push_error("Decision nulla allo step %d" % current_step)
		return
	var nome_base: String = decision.personaggio_id
	var proposer: Personaggio = personaggi_db.get(decision.personaggio_id)
	if proposer != null:
		proposer_portrait.texture = proposer.ritratto
		nome_base = "%s — %s" % [proposer.nome, proposer.archetipo]
	else:
		proposer_portrait.texture = null
	var prefisso: String = PREFISSO_TIPO.get(decision.tipo_decisione, "")
	proposer_name_label.text = prefisso + nome_base
	proposer_name_label.modulate = _colore_proposer(decision.tipo_decisione)
	proposer_text_label.text = decision.testo_consigliere
	_imposta_event_image(decision.illustrazione_id)
	_setup_consiglieri_for_decision(decision)
	_setup_decision_panel_for_decision(decision)


func _imposta_event_image(illustrazione_id: String) -> void:
	if event_image == null:
		return
	if illustrazione_id == "":
		event_image.visible = false
		event_image.texture = null
		return
	var path: String = "res://Assets/art/eventi/%s.png" % illustrazione_id
	if ResourceLoader.exists(path):
		event_image.texture = load(path)
		event_image.visible = true
	else:
		event_image.visible = false


func _setup_consiglieri_for_decision(decision: Decision) -> void:
	var targets_accepts: Dictionary = {}
	for opt in decision.opzioni:
		if opt == null:
			continue
		var cid: String = opt.target_consigliere_id
		if cid == "":
			continue
		if not targets_accepts.has(cid):
			targets_accepts[cid] = []
		var sid: String = opt.strategia.id if opt.strategia != null else ""
		if sid != "" and sid not in targets_accepts[cid]:
			targets_accepts[cid].append(sid)
	_decision_accents.clear()
	var idx: int = 0
	for cid in targets_accepts.keys():
		var zone: Control = DROP_ZONE_SCENE.instantiate()
		zone.zone_id = cid
		var accent: Color = ACCENT_PALETTE[idx % ACCENT_PALETTE.size()]
		_decision_accents[cid] = accent
		zone.accent_color = accent
		idx += 1
		var pers: Personaggio = personaggi_db.get(cid)
		if pers != null:
			zone.label_text = "%s\n%s" % [pers.nome, pers.archetipo]
			zone.portrait_texture = pers.ritratto
		else:
			zone.label_text = cid
		var accepts: Array[String] = []
		for sid in targets_accepts[cid]:
			accepts.append(sid)
		zone.accepted_item_ids = accepts
		consiglieri_row.add_child(zone)
		zone.item_dropped.connect(_on_item_dropped)


func _setup_decision_panel_for_decision(decision: Decision) -> void:
	for opt in decision.opzioni:
		if opt == null:
			continue
		var item: Control = DRAG_ITEM_SCENE.instantiate()
		var sid: String = opt.strategia.id if opt.strategia != null else ""
		item.item_id = sid
		item.label_text = opt.label_text
		var tgt: Personaggio = personaggi_db.get(opt.target_consigliere_id)
		if tgt != null:
			var nome_tgt: String = tgt.nome.split(" ")[0]
			item.target_text = "→ %s" % nome_tgt
			item.hint_text = "Trascina su %s" % nome_tgt
			item.target_color = _decision_accents.get(opt.target_consigliere_id, item.target_color)
		item.icon_texture = opt.icona_drag
		item.feedback_text = opt.feedback_testo
		decision_panel_row.add_child(item)
		item.set_meta("option", opt)
		if not opt.is_disponibile():
			item.set_disabled(true, opt.motivo_indisponibilita())


func _on_item_dropped(data: Dictionary) -> void:
	if processing_drop:
		return
	processing_drop = true
	AudioManager.play_sfx("drop_success")
	var source_node: Control = data.get("source") as Control
	if source_node == null or not source_node.has_meta("option"):
		processing_drop = false
		return
	var option: DecisionOption = source_node.get_meta("option") as DecisionOption
	if option == null:
		processing_drop = false
		return
	GameState.apply_effect(option.effetto)
	SaveSystem.save_run()
	_show_narrative(option.feedback_testo)
	if source_node.has_method("consume"):
		source_node.consume()
	await get_tree().create_timer(FEEDBACK_PAUSE_SEC).timeout
	if not is_inside_tree():
		processing_drop = false
		return
	current_step += 1
	_show_current_decision()
	processing_drop = false


func _complete_quest() -> void:
	if current_quest == null:
		return
	GameState.apply_effect(current_quest.effetto_completamento)
	QuestManager.completa_quest(current_quest)
	SaveSystem.save_run()
	AudioManager.play_sfx("quest_complete")
	current_quest = null
	_avvia_prossima_quest()


func _show_narrative(text: String) -> void:
	narrative_label.text = text
	if text.is_empty():
		narrative_label.modulate.a = 0.0
		return
	narrative_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(narrative_label, "modulate:a", 1.0, NARRATIVE_FADE_DURATION)


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _on_stat_changed(nome: String, vecchio: int, nuovo: int) -> void:
	var label: Label = stat_value_labels.get(nome)
	if label == null:
		return
	if stat_tweens.has(nome) and stat_tweens[nome] != null:
		(stat_tweens[nome] as Tween).kill()
	var tween: Tween = create_tween()
	stat_tweens[nome] = tween
	var stat_label: String = STAT_LABELS[nome]
	tween.tween_method(
		func(value: float) -> void:
			if is_instance_valid(label):
				label.text = "%s: %d" % [stat_label, int(round(value))],
		float(vecchio),
		float(nuovo),
		STAT_TWEEN_DURATION,
	)
	var flash_color: Color = Color(0.6, 1.0, 0.6) if nuovo > vecchio else Color(1.0, 0.6, 0.6)
	label.modulate = flash_color
	var color_tween: Tween = create_tween()
	color_tween.tween_property(label, "modulate", Color.WHITE, STAT_TWEEN_DURATION + 0.2)
	AudioManager.play_sfx("stat_up" if nuovo > vecchio else "stat_down")
	_refresh_disabled_options()
	if in_attesa_quest:
		_avvia_prossima_quest()


func _on_mystery_attivata() -> void:
	var bg: ColorRect = $UI/Background
	if bg != null:
		var t: Tween = create_tween()
		t.tween_property(bg, "color", COLOR_BG_MYSTERY, 1.5)
	Ledger.unlock_evento("fiume_rosso")
	Ledger.unlock_lore("lore_fiume_rosso")
	AudioManager.play_sfx("quest_complete")
	_show_narrative("Il fuoco arde di un rosso che non conosce. Oltre la fiamma, qualcosa ascolta.")


func _on_popolazione_changed(vecchio: int, nuovo: int) -> void:
	if popolazione_label == null:
		return
	popolazione_label.text = "Popolazione: %d" % nuovo
	var flash_color: Color = Color(0.6, 1.0, 0.6) if nuovo > vecchio else Color(1.0, 0.6, 0.6)
	popolazione_label.modulate = flash_color
	var tween: Tween = create_tween()
	tween.tween_property(popolazione_label, "modulate", Color.WHITE, STAT_TWEEN_DURATION + 0.2)


func _on_rapporto_changed(_civ_id: String, _vecchio: int, _nuovo: int) -> void:
	_refresh_rapporti()


func _refresh_rapporti() -> void:
	if rapporti_label == null or rapporti_box == null:
		return
	_clear_children(rapporti_box)
	var qualcuno: bool = false
	for civ_id in GameState.rapporti_civilta.keys():
		var valore: int = int(GameState.rapporti_civilta[civ_id])
		if valore == 0 and not CIV_LABELS.has(civ_id):
			continue
		qualcuno = true
		var nome: String = CIV_LABELS.get(civ_id, civ_id)
		var segno: String = "+" if valore > 0 else ""
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var face: TextureRect = TextureRect.new()
		face.custom_minimum_size = Vector2(38, 38)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var face_path: String = "res://Assets/art/ambasciatori/%s.png" % civ_id
		if ResourceLoader.exists(face_path):
			face.texture = load(face_path)
		row.add_child(face)
		var lbl: Label = Label.new()
		lbl.text = "%s\n%s%d" % [nome, segno, valore]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var col_val: Color = Color(0.6, 1.0, 0.6) if valore > 0 else (Color(1.0, 0.6, 0.6) if valore < 0 else Color(1, 1, 1, 0.8))
		lbl.add_theme_color_override("font_color", col_val)
		row.add_child(lbl)
		rapporti_box.add_child(row)
	rapporti_label.text = "Rapporti:" if qualcuno else ""


func _colore_proposer(tipo: String) -> Color:
	match tipo:
		"catastrofe": return COLOR_PROPOSER_CATASTROFE
		"svolta": return COLOR_PROPOSER_SVOLTA
		"mistero": return COLOR_PROPOSER_MISTERO
		_: return COLOR_PROPOSER_NORMALE


func _refresh_disabled_options() -> void:
	for item in decision_panel_row.get_children():
		if not item.has_meta("option"):
			continue
		var opt: DecisionOption = item.get_meta("option") as DecisionOption
		if opt == null:
			continue
		if not item.has_method("set_disabled"):
			continue
		if opt.is_disponibile():
			item.set_disabled(false)
		else:
			item.set_disabled(true, opt.motivo_indisponibilita())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_L: _toggle_ledger()
		KEY_ENTER, KEY_KP_ENTER:
			if in_transizione_era:
				_entra_era2()
		KEY_ESCAPE: _on_escape()
		_:
			if OS.is_debug_build():
				_debug_input(event.keycode)


func _debug_input(keycode: int) -> void:
	match keycode:
		KEY_R: _reset_run()
		KEY_1: GameState.modifica_stat("militare", 5)
		KEY_2: GameState.modifica_stat("tesoro", 5)
		KEY_3: GameState.modifica_stat("diplomazia", 5)
		KEY_4: GameState.modifica_stat("scienza", 5)
		KEY_5: GameState.modifica_stat("legge", 5)
		KEY_6: GameState.modifica_stat("spionaggio", 5)
		KEY_7: GameState.modifica_stat("popolo", 5)
		KEY_8: GameState.modifica_stat("costruzione", 5)


func _on_escape() -> void:
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		_close_ledger_if_open()
		return
	_toggle_pause()


func _toggle_pause() -> void:
	if pause_instance != null and is_instance_valid(pause_instance):
		_close_pause()
		return
	pause_instance = PAUSE_SCENE.instantiate()
	pause_instance.connect("resumed", _close_pause)
	add_child(pause_instance)
	get_tree().paused = true


func _close_pause() -> void:
	get_tree().paused = false
	if pause_instance != null and is_instance_valid(pause_instance):
		pause_instance.queue_free()
		pause_instance = null


func _toggle_ledger() -> void:
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		_close_ledger_if_open()
	else:
		ledger_screen_instance = LEDGER_SCENE.instantiate()
		add_child(ledger_screen_instance)


func _close_ledger_if_open() -> void:
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		ledger_screen_instance.queue_free()
		ledger_screen_instance = null


func _reset_run() -> void:
	GameState.reset_run()
	_show_narrative("")
	in_transizione_era = false
	if ending_instance != null and is_instance_valid(ending_instance):
		ending_instance.queue_free()
		ending_instance = null
	var bg: ColorRect = $UI/Background
	if bg != null:
		bg.color = COLOR_BG_ERA1
	_refresh_rapporti()
	_start_era1()
