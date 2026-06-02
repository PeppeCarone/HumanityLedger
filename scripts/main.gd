extends Node2D

const DROP_ZONE_SCENE: PackedScene = preload("res://scenes/ui/drop_zone.tscn")
const DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/ui/draggable_item.tscn")

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
@onready var version_label: Label = $UI/VersionLabel
@onready var help_label: Label = $UI/HelpLabel


func _ready() -> void:
	version_label.text = "W2 prototipo drag-and-drop — premi R per reset, 1-8 debug stat"
	help_label.text = "Trascina un oggetto sul consigliere che lo accetta. Drop fuori target = annullamento."
	_setup_hud()
	_setup_consiglieri()
	_setup_decision_panel()
	GameState.stat_changed.connect(_on_stat_changed)


func _setup_hud() -> void:
	for stat_name in GameState.STAT_NAMES:
		var label: Label = Label.new()
		label.name = "Stat_" + stat_name
		label.text = "%s: %d" % [STAT_LABELS[stat_name], GameState.get_stat(stat_name)]
		label.add_theme_font_size_override("font_size", 22)
		hud_container.add_child(label)


func _setup_consiglieri() -> void:
	var defs: Array = [
		{"id": "cacciatore", "nome": "Brann\n(Cacciatore-Capo)", "color": Color(0.45, 0.2, 0.18, 1), "accepts": ["spada", "ascia"]},
		{"id": "sciamana", "nome": "Lyssa\n(Sciamana)", "color": Color(0.25, 0.3, 0.45, 1), "accepts": ["pergamena", "torcia"]},
		{"id": "plasmatore", "nome": "Tev\n(Plasmatore)", "color": Color(0.4, 0.3, 0.2, 1), "accepts": ["ascia", "pietra"]},
		{"id": "anziano", "nome": "Murr\n(Anziano)", "color": Color(0.3, 0.3, 0.2, 1), "accepts": ["runa", "pergamena"]},
	]
	for c in defs:
		var zone: Control = DROP_ZONE_SCENE.instantiate()
		consiglieri_row.add_child(zone)
		zone.zone_id = c["id"]
		zone.label_text = c["nome"]
		zone.bg_color = c["color"]
		var accepts: Array[String] = []
		for s in c["accepts"]:
			accepts.append(s)
		zone.accepted_item_ids = accepts
		zone.item_dropped.connect(_on_item_dropped)


func _setup_decision_panel() -> void:
	var defs: Array = [
		{
			"id": "spada",
			"label": "Spada\n(Militare +8)",
			"color": Color(0.65, 0.2, 0.2, 1),
			"stat": "militare",
			"delta": 8,
			"feedback": "Brann impugna la spada e annuisce. Il ferro parla per primo.",
		},
		{
			"id": "pergamena",
			"label": "Pergamena\n(Scienza +8)",
			"color": Color(0.85, 0.75, 0.5, 1),
			"stat": "scienza",
			"delta": 8,
			"feedback": "Lyssa ripone il segno tra le sue ossa di memoria.",
		},
		{
			"id": "ascia",
			"label": "Ascia\n(Costruzione +8)",
			"color": Color(0.45, 0.3, 0.2, 1),
			"stat": "costruzione",
			"delta": 8,
			"feedback": "Tev solleva l'ascia. Il legno comincia a cedere.",
		},
	]
	for it in defs:
		var item: Control = DRAG_ITEM_SCENE.instantiate()
		decision_panel_row.add_child(item)
		item.item_id = it["id"]
		item.label_text = it["label"]
		item.icon_color = it["color"]
		item.stat_to_modify = it["stat"]
		item.stat_delta = it["delta"]
		item.feedback_text = it["feedback"]


func _on_item_dropped(data: Dictionary) -> void:
	var stat_name: String = data.get("stat", "")
	var delta: int = data.get("delta", 0)
	if stat_name != "":
		GameState.modifica_stat(stat_name, delta)
	var feedback: String = data.get("feedback", "")
	if feedback != "":
		narrative_label.text = feedback
	var source: Variant = data.get("source")
	if source != null and source is Control and source.has_method("consume"):
		source.consume()


func _on_stat_changed(nome: String, _vecchio: int, nuovo: int) -> void:
	var label: Label = hud_container.get_node_or_null("Stat_" + nome)
	if label != null:
		label.text = "%s: %d" % [STAT_LABELS[nome], nuovo]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: _reset_demo()
			KEY_1: GameState.modifica_stat("militare", 5)
			KEY_2: GameState.modifica_stat("tesoro", 5)
			KEY_3: GameState.modifica_stat("diplomazia", 5)
			KEY_4: GameState.modifica_stat("scienza", 5)
			KEY_5: GameState.modifica_stat("legge", 5)
			KEY_6: GameState.modifica_stat("spionaggio", 5)
			KEY_7: GameState.modifica_stat("popolo", 5)
			KEY_8: GameState.modifica_stat("costruzione", 5)


func _reset_demo() -> void:
	GameState.reset_run()
	narrative_label.text = ""
	for item in decision_panel_row.get_children():
		if item.has_method("reset"):
			item.reset()
