extends Control

const GAME_SCENE: String = "res://scenes/main.tscn"
const LEDGER_SCENE: PackedScene = preload("res://scenes/ledger_screen.tscn")

@onready var nuova_btn: Button = $Buttons/NuovaPartita
@onready var continua_btn: Button = $Buttons/Continua
@onready var ledger_btn: Button = $Buttons/Ledger
@onready var esci_btn: Button = $Buttons/Esci

var ledger_instance: CanvasLayer = null


func _ready() -> void:
	nuova_btn.pressed.connect(_on_nuova)
	continua_btn.pressed.connect(_on_continua)
	ledger_btn.pressed.connect(_on_ledger)
	esci_btn.pressed.connect(_on_esci)
	var ha_save: bool = SaveSystem.exists_run()
	continua_btn.disabled = not ha_save
	if not ha_save:
		continua_btn.tooltip_text = "Nessuna partita salvata."
	nuova_btn.grab_focus()


func _on_nuova() -> void:
	SaveSystem.reset_run()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_continua() -> void:
	if not SaveSystem.exists_run():
		return
	SaveSystem.load_run()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_ledger() -> void:
	if ledger_instance != null and is_instance_valid(ledger_instance):
		return
	ledger_instance = LEDGER_SCENE.instantiate()
	add_child(ledger_instance)


func _on_esci() -> void:
	get_tree().quit()
