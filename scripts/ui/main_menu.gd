extends Control

const GAME_SCENE: String = "res://scenes/main.tscn"
const LEDGER_SCENE: PackedScene = preload("res://scenes/ledger_screen.tscn")
const OPTIONS_SCENE: PackedScene = preload("res://scenes/ui/options_menu.tscn")
const BG_PATH: String = "res://Assets/art/ui/main_menu_bg.png"

@onready var background: TextureRect = $Background
@onready var nuova_btn: Button = $Buttons/NuovaPartita
@onready var continua_btn: Button = $Buttons/Continua
@onready var ledger_btn: Button = $Buttons/Ledger
@onready var esci_btn: Button = $Buttons/Esci

var ledger_instance: CanvasLayer = null
var options_instance: CanvasLayer = null
var opzioni_btn: Button = null


func _ready() -> void:
	if ResourceLoader.exists(BG_PATH):
		background.texture = load(BG_PATH)
	# Vignette cinematografica (stesso shader di villaggio/mappa): sopra lo sfondo, sotto
	# i pulsanti. Isola il titolo e affonda i bordi nel buio.
	var vignette: ColorRect = UiStyle.crea_vignette(0.34, Color(0, 0, 0, 1))
	vignette.name = "Vignette"
	add_child(vignette)
	move_child(vignette, background.get_index() + 1)
	# Cornici d'angolo "tomo rilegato" allo schermo (coerenti col Ledger): incorniciano il menu.
	UiStyle.aggiungi_cornici(self, get_viewport_rect(), 168.0, 0.85)
	nuova_btn.pressed.connect(_on_nuova)
	continua_btn.pressed.connect(_on_continua)
	ledger_btn.pressed.connect(_on_ledger)
	esci_btn.pressed.connect(_on_esci)
	_usa_tema_globale()
	_stilizza_primario()
	_aggiungi_tagline()
	_badge_eone()
	_setup_hover()
	for b in [nuova_btn, continua_btn, ledger_btn, esci_btn]:
		b.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click"))
	# Pulsante Opzioni (deliverable d'esame): inserito prima di "Esci", tema globale.
	opzioni_btn = Button.new()
	opzioni_btn.text = "Opzioni"
	$Buttons.add_child(opzioni_btn)
	$Buttons.move_child(opzioni_btn, esci_btn.get_index())
	opzioni_btn.pressed.connect(_on_opzioni)
	opzioni_btn.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click"))
	opzioni_btn.mouse_entered.connect(_hover_in.bind(opzioni_btn))
	opzioni_btn.mouse_exited.connect(_hover_out.bind(opzioni_btn))
	opzioni_btn.focus_entered.connect(_hover_in.bind(opzioni_btn))
	opzioni_btn.focus_exited.connect(_hover_out.bind(opzioni_btn))
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


# Badge "Eone N · <Mutatore>" in alto a destra quando si è in Nuovo Ciclo+: ricorda
# al giocatore di ritorno il tier di rigiocabilità raggiunto. Niente alla prima vita.
func _badge_eone() -> void:
	if not Ledger.in_eone():
		return
	var box: PanelContainer = PanelContainer.new()
	box.name = "BadgeEone"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.09, 0.72)
	sb.border_color = Color(0.72, 0.55, 0.95, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	box.add_theme_stylebox_override("panel", sb)
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.anchor_top = 0.0
	box.anchor_bottom = 0.0
	# A sinistra della cornice d'angolo (168px) per non sovrapporsi al filigrana dorato.
	box.offset_left = -520.0
	box.offset_right = -188.0
	box.offset_top = 30.0
	box.offset_bottom = 78.0
	add_child(box)
	var lbl: Label = Label.new()
	lbl.text = "✦ %s · %s" % [Ledger.eone_nome(), Ledger.mutatore_nome()]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.8, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 4)
	var cinzel: String = "res://Assets/fonts/Cinzel.ttf"
	if ResourceLoader.exists(cinzel):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel)
		fv.variation_opentype = {"wght": 600}
		lbl.add_theme_font_override("font", fv)
	box.add_child(lbl)
	box.modulate = Color(1, 1, 1, 0)
	var tw2: Tween = create_tween()
	tw2.tween_interval(0.3)
	tw2.tween_property(box, "modulate:a", 1.0, 0.7)


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


func _on_opzioni() -> void:
	if options_instance != null and is_instance_valid(options_instance):
		return
	options_instance = OPTIONS_SCENE.instantiate()
	add_child(options_instance)


func _on_esci() -> void:
	get_tree().quit()
