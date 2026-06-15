extends Control

const GAME_SCENE: String = "res://scenes/main.tscn"
const LEDGER_SCENE: PackedScene = preload("res://scenes/ledger_screen.tscn")
const BG_PATH: String = "res://Assets/art/ui/main_menu_bg.png"

@onready var background: TextureRect = $Background
@onready var nuova_btn: Button = $Buttons/NuovaPartita
@onready var continua_btn: Button = $Buttons/Continua
@onready var ledger_btn: Button = $Buttons/Ledger
@onready var esci_btn: Button = $Buttons/Esci

var ledger_instance: CanvasLayer = null


func _ready() -> void:
	if ResourceLoader.exists(BG_PATH):
		background.texture = load(BG_PATH)
	nuova_btn.pressed.connect(_on_nuova)
	continua_btn.pressed.connect(_on_continua)
	ledger_btn.pressed.connect(_on_ledger)
	esci_btn.pressed.connect(_on_esci)
	_usa_tema_globale()
	_stilizza_primario()
	_aggiungi_tagline()
	_setup_hover()
	for b in [nuova_btn, continua_btn, ledger_btn, esci_btn]:
		b.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click"))
	var ha_save: bool = SaveSystem.exists_run()
	continua_btn.disabled = not ha_save
	if not ha_save:
		continua_btn.tooltip_text = "Nessuna partita salvata."
	nuova_btn.grab_focus()
	_anima_ingresso()
	AudioManager.play_music_id("menu")


# Tutti i pulsanti del menu usano il tema globale (cornici §P8 con fallback bronzo),
# togliendo gli override flat del .tscn: coerenza totale con i pulsanti in-gioco.
func _usa_tema_globale() -> void:
	for b in [nuova_btn, continua_btn, ledger_btn, esci_btn]:
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.remove_theme_stylebox_override(st)


# "Nuova Partita" è l'azione principale: porta sempre la cornice "accesa" (lo stato hover)
# come stato normale, così spicca, ed è un po' più grande.
func _stilizza_primario() -> void:
	var acceso: StyleBox = nuova_btn.get_theme_stylebox("hover", "Button")
	nuova_btn.add_theme_stylebox_override("normal", acceso)
	nuova_btn.add_theme_font_size_override("font_size", 32)


# Sottotitolo evocativo sopra i pulsanti: dice in una riga di cosa parla il gioco.
func _aggiungi_tagline() -> void:
	var t: Label = Label.new()
	t.text = "Lo spirito del popolo attraversa le ere.\nOgni scelta resta."
	t.add_theme_font_size_override("font_size", 21)
	t.add_theme_color_override("font_color", Color(0.88, 0.80, 0.62))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	t.add_theme_constant_override("outline_size", 5)
	t.add_theme_constant_override("line_spacing", 2)
	t.position = Vector2(112.0, 470.0)
	t.size = Vector2(440.0, 80.0)
	add_child(t)
	t.modulate = Color(1, 1, 1, 0)
	var tw: Tween = create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(t, "modulate:a", 1.0, 0.7)


func _setup_hover() -> void:
	for b in [nuova_btn, continua_btn, ledger_btn, esci_btn]:
		b.mouse_entered.connect(_hover_in.bind(b))
		b.mouse_exited.connect(_hover_out.bind(b))
		b.focus_entered.connect(_hover_in.bind(b))
		b.focus_exited.connect(_hover_out.bind(b))


func _hover_in(b: Button) -> void:
	if b.disabled:
		return
	b.pivot_offset = b.size * 0.5
	var tw: Tween = create_tween()
	tw.tween_property(b, "scale", Vector2(1.05, 1.05), 0.12) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hover_out(b: Button) -> void:
	if b.has_focus():
		return
	var tw: Tween = create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE)


# Ingresso a cascata: i pulsanti appaiono in dissolvenza dall'alto verso il basso.
func _anima_ingresso() -> void:
	var btns: Array[Button] = [nuova_btn, continua_btn, ledger_btn, esci_btn]
	for i in btns.size():
		var b: Button = btns[i]
		b.modulate = Color(1, 1, 1, 0)
		var tw: Tween = create_tween()
		tw.tween_interval(0.09 * i + 0.1)
		tw.tween_property(b, "modulate:a", 1.0, 0.32)


func _on_nuova() -> void:
	SaveSystem.reset_run()
	var err: int = get_tree().change_scene_to_file(GAME_SCENE)
	if err != OK:
		push_error("Nuova Partita: change_scene fallito (err %d) su %s" % [err, GAME_SCENE])


func _on_continua() -> void:
	if not SaveSystem.exists_run():
		return
	SaveSystem.load_run()
	var err: int = get_tree().change_scene_to_file(GAME_SCENE)
	if err != OK:
		push_error("Continua: change_scene fallito (err %d) su %s" % [err, GAME_SCENE])


func _on_ledger() -> void:
	if ledger_instance != null and is_instance_valid(ledger_instance):
		return
	ledger_instance = LEDGER_SCENE.instantiate()
	add_child(ledger_instance)


func _on_esci() -> void:
	get_tree().quit()
