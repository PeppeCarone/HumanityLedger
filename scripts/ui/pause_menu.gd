extends CanvasLayer

const MENU_SCENE: String = "res://scenes/main_menu.tscn"

signal resumed

@onready var audio_btn: Button = $Dim/Panel/VBox/Audio
@onready var riprendi_btn: Button = $Dim/Panel/VBox/Riprendi
@onready var menu_btn: Button = $Dim/Panel/VBox/TornaMenu


@onready var titolo: Label = $Dim/Panel/VBox/Titolo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	riprendi_btn.pressed.connect(_on_riprendi)
	audio_btn.pressed.connect(_on_audio)
	menu_btn.pressed.connect(_on_menu)
	for b in [riprendi_btn, audio_btn, menu_btn]:
		b.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click"))
	var cinzel_path: String = "res://Assets/fonts/Cinzel.ttf"
	if titolo != null and ResourceLoader.exists(cinzel_path):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel_path)
		fv.variation_opentype = {"wght": 700}
		titolo.add_theme_font_override("font", fv)
	_refresh_audio_label()
	riprendi_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		resumed.emit()


func _refresh_audio_label() -> void:
	audio_btn.text = "Audio: Off" if AudioManager.is_muted() else "Audio: On"


func _on_riprendi() -> void:
	resumed.emit()


func _on_audio() -> void:
	AudioManager.toggle_muted()
	_refresh_audio_label()


func _on_menu() -> void:
	SaveSystem.save_run()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
