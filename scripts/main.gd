extends Node2D

const DROP_ZONE_SCENE: PackedScene = preload("res://scenes/ui/drop_zone.tscn")
const DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/ui/draggable_item.tscn")
const TUTORIAL_QUEST_PATH: String = "res://data/quests/q_caverna_tutorial.tres"
const CHARACTERS_DIR: String = "res://data/characters/"
const FEEDBACK_PAUSE_SEC: float = 2.5

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

@onready var hud_container: VBoxContainer = $UI/HUDPanel/VBoxContainer
@onready var consiglieri_row: HBoxContainer = $UI/ConsiglieriRow
@onready var decision_panel_row: HBoxContainer = $UI/DecisionPanel/HBoxContainer
@onready var narrative_label: Label = $UI/NarrativeLabel
@onready var help_label: Label = $UI/HelpLabel
@onready var proposer_portrait: TextureRect = $UI/ConsigliereProposer/HBox/PortraitProposer
@onready var proposer_name_label: Label = $UI/ConsigliereProposer/HBox/VBox/ProposerName
@onready var proposer_text_label: Label = $UI/ConsigliereProposer/HBox/VBox/ProposerText

var quest_log_label: Label = null
var current_quest: Quest = null
var current_step: int = 0
var personaggi_db: Dictionary = {}
var processing_drop: bool = false


func _ready() -> void:
	help_label.text = "Trascina l'icona sul consigliere proponente. Opzioni grigie = prerequisito non soddisfatto (hover per dettagli). R reset, 1-8 debug stat."
	_setup_hud()
	_load_personaggi()
	_start_tutorial()
	GameState.stat_changed.connect(_on_stat_changed)


func _setup_hud() -> void:
	for stat_name in GameState.STAT_NAMES:
		var label: Label = Label.new()
		label.name = "Stat_" + stat_name
		label.text = "%s: %d" % [STAT_LABELS[stat_name], GameState.get_stat(stat_name)]
		label.add_theme_font_size_override("font_size", 20)
		hud_container.add_child(label)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	hud_container.add_child(spacer)
	quest_log_label = Label.new()
	quest_log_label.name = "QuestLog"
	quest_log_label.add_theme_font_size_override("font_size", 18)
	quest_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_container.add_child(quest_log_label)


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


func _start_tutorial() -> void:
	current_quest = load(TUTORIAL_QUEST_PATH) as Quest
	if current_quest == null:
		push_error("Quest tutorial non caricabile: " + TUTORIAL_QUEST_PATH)
		return
	QuestManager.quest_attive.clear()
	QuestManager.quest_chiave_corrente = null
	QuestManager.avvia_quest(current_quest)
	current_step = 0
	_show_current_decision()


func _show_current_decision() -> void:
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	narrative_label.text = ""
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
	var proposer: Personaggio = personaggi_db.get(decision.personaggio_id)
	if proposer != null:
		proposer_portrait.texture = proposer.ritratto
		proposer_name_label.text = "%s — %s" % [proposer.nome, proposer.archetipo]
	else:
		proposer_portrait.texture = null
		proposer_name_label.text = decision.personaggio_id
	proposer_text_label.text = decision.testo_consigliere
	_setup_consiglieri_for_decision(decision)
	_setup_decision_panel_for_decision(decision)


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
	for cid in targets_accepts.keys():
		var zone: Control = DROP_ZONE_SCENE.instantiate()
		consiglieri_row.add_child(zone)
		zone.zone_id = cid
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
		zone.item_dropped.connect(_on_item_dropped)


func _setup_decision_panel_for_decision(decision: Decision) -> void:
	for opt in decision.opzioni:
		if opt == null:
			continue
		var item: Control = DRAG_ITEM_SCENE.instantiate()
		decision_panel_row.add_child(item)
		var sid: String = opt.strategia.id if opt.strategia != null else ""
		item.item_id = sid
		item.label_text = opt.label_text
		item.icon_texture = opt.icona_drag
		item.feedback_text = opt.feedback_testo
		item.set_meta("option", opt)
		if not opt.is_disponibile():
			item.set_disabled(true, opt.motivo_indisponibilita())


func _on_item_dropped(data: Dictionary) -> void:
	if processing_drop:
		return
	processing_drop = true
	var source: Variant = data.get("source")
	var option: DecisionOption = null
	if source != null and source is Control and source.has_meta("option"):
		option = source.get_meta("option") as DecisionOption
	if option == null:
		processing_drop = false
		return
	GameState.apply_effect(option.effetto)
	narrative_label.text = option.feedback_testo
	if source.has_method("consume"):
		source.consume()
	await get_tree().create_timer(FEEDBACK_PAUSE_SEC).timeout
	current_step += 1
	_show_current_decision()
	processing_drop = false


func _complete_quest() -> void:
	if current_quest == null:
		return
	GameState.apply_effect(current_quest.effetto_completamento)
	QuestManager.completa_quest(current_quest)
	proposer_portrait.texture = null
	proposer_name_label.text = "Il consiglio è pronto"
	proposer_text_label.text = "La caverna ha imparato il loro nome. La trama continuerà nei prossimi atti."
	narrative_label.text = "Quest completata: %s" % current_quest.titolo
	quest_log_label.text = "Quest: completata"
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _on_stat_changed(nome: String, _vecchio: int, nuovo: int) -> void:
	var label: Label = hud_container.get_node_or_null("Stat_" + nome)
	if label != null:
		label.text = "%s: %d" % [STAT_LABELS[nome], nuovo]
	_refresh_disabled_options()


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
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: _reset_run()
			KEY_1: GameState.modifica_stat("militare", 5)
			KEY_2: GameState.modifica_stat("tesoro", 5)
			KEY_3: GameState.modifica_stat("diplomazia", 5)
			KEY_4: GameState.modifica_stat("scienza", 5)
			KEY_5: GameState.modifica_stat("legge", 5)
			KEY_6: GameState.modifica_stat("spionaggio", 5)
			KEY_7: GameState.modifica_stat("popolo", 5)
			KEY_8: GameState.modifica_stat("costruzione", 5)


func _reset_run() -> void:
	GameState.reset_run()
	narrative_label.text = ""
	_start_tutorial()
