extends Node2D

@onready var stats_container: VBoxContainer = $UI/StatsPanel/VBoxContainer
@onready var version_label: Label = $UI/VersionLabel

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


func _ready() -> void:
	version_label.text = "HumanityLedger — W1 setup placeholder"
	for stat_name in GameState.STAT_NAMES:
		var label: Label = Label.new()
		label.name = "Stat_" + stat_name
		label.text = "%s: %d" % [STAT_LABELS[stat_name], GameState.get_stat(stat_name)]
		stats_container.add_child(label)
	GameState.stat_changed.connect(_on_stat_changed)


func _on_stat_changed(nome: String, _vecchio: int, nuovo: int) -> void:
	var label: Label = stats_container.get_node_or_null("Stat_" + nome)
	if label != null:
		label.text = "%s: %d" % [STAT_LABELS[nome], nuovo]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: GameState.modifica_stat("militare", 5)
			KEY_2: GameState.modifica_stat("tesoro", 5)
			KEY_3: GameState.modifica_stat("diplomazia", 5)
			KEY_4: GameState.modifica_stat("scienza", 5)
			KEY_5: GameState.modifica_stat("legge", 5)
			KEY_6: GameState.modifica_stat("spionaggio", 5)
			KEY_7: GameState.modifica_stat("popolo", 5)
			KEY_8: GameState.modifica_stat("costruzione", 5)
			KEY_R: GameState.reset_run()
