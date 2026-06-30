extends CanvasLayer

# Menu Opzioni (deliverable d'esame): volume musica/SFX, mute, schermo intero,
# risoluzione, rigioca tutorial. Overlay riusabile da menu principale e pausa.
# Le impostazioni sono persistite da AudioManager (user://settings.cfg).

signal chiuso

const GAME_SCENE: String = "res://scenes/main.tscn"
const RES_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var _res_btn: OptionButton = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_costruisci()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_chiudi()


func _costruisci() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var box: PanelContainer = PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.panel_stylebox())
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -360.0
	box.offset_right = 360.0
	box.offset_top = -318.0
	box.offset_bottom = 318.0
	dim.add_child(box)

	var margine: MarginContainer = MarginContainer.new()
	margine.add_theme_constant_override("margin_left", 28)
	margine.add_theme_constant_override("margin_right", 28)
	margine.add_theme_constant_override("margin_top", 16)
	margine.add_theme_constant_override("margin_bottom", 16)
	box.add_child(margine)
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	margine.add_child(vb)

	var titolo: Label = Label.new()
	titolo.text = "Opzioni"
	titolo.add_theme_font_size_override("font_size", 30)
	titolo.add_theme_color_override("font_color", Color(0.93, 0.82, 0.5))
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cinzel: String = "res://Assets/fonts/Cinzel.ttf"
	if ResourceLoader.exists(cinzel):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel)
		fv.variation_opentype = {"wght": 600}
		titolo.add_theme_font_override("font", fv)
	vb.add_child(titolo)
	vb.add_child(_separatore())

	# Volume musica / SFX.
	_riga_slider(vb, "Musica", AudioManager.music_volume(), func(v: float) -> void:
		AudioManager.set_music_volume(v))
	_riga_slider(vb, "Effetti", AudioManager.sfx_volume(), func(v: float) -> void:
		AudioManager.set_sfx_volume(v)
		AudioManager.play_sfx("ui_click"))

	# Silenzia tutto.
	var mute: CheckButton = CheckButton.new()
	mute.text = "Silenzia tutto"
	mute.button_pressed = AudioManager.is_muted()
	mute.toggled.connect(func(on: bool) -> void: AudioManager.set_muted(on))
	vb.add_child(mute)

	vb.add_child(_separatore())

	# Schermo intero.
	var fs: CheckButton = CheckButton.new()
	fs.text = "Schermo intero"
	fs.button_pressed = AudioManager.is_fullscreen()
	fs.toggled.connect(func(on: bool) -> void:
		AudioManager.set_fullscreen(on)
		if _res_btn != null:
			_res_btn.disabled = on)
	vb.add_child(fs)

	# Risoluzione (in finestra).
	var rrow: HBoxContainer = HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 12)
	var rlbl: Label = _lbl("Risoluzione")
	rlbl.custom_minimum_size = Vector2(120, 0)
	rrow.add_child(rlbl)
	_res_btn = OptionButton.new()
	var cur: Vector2i = DisplayServer.window_get_size()
	for i in RES_PRESETS.size():
		var r: Vector2i = RES_PRESETS[i]
		_res_btn.add_item("%d x %d" % [r.x, r.y], i)
		if r == cur or r == AudioManager.resolution():
			_res_btn.select(i)
	_res_btn.disabled = AudioManager.is_fullscreen()
	_res_btn.item_selected.connect(func(idx: int) -> void:
		AudioManager.set_resolution(RES_PRESETS[idx]))
	rrow.add_child(_res_btn)
	vb.add_child(rrow)

	vb.add_child(_separatore())

	# Difficoltà (preferenza di gioco): incide su Assedio + HP villaggio.
	var drow: HBoxContainer = HBoxContainer.new()
	drow.add_theme_constant_override("separation", 12)
	var dlbl: Label = _lbl("Difficoltà")
	dlbl.custom_minimum_size = Vector2(120, 0)
	drow.add_child(dlbl)
	var dbtn: OptionButton = OptionButton.new()
	for i in AudioManager.DIFFICOLTA_NOMI.size():
		dbtn.add_item(AudioManager.DIFFICOLTA_NOMI[i], i)
	dbtn.select(AudioManager.difficolta())
	drow.add_child(dbtn)
	vb.add_child(drow)
	var ddesc: Label = _lbl(AudioManager.DIFFICOLTA_DESCR[AudioManager.difficolta()])
	ddesc.add_theme_font_size_override("font_size", 14)
	ddesc.add_theme_color_override("font_color", Color(0.78, 0.72, 0.6))
	ddesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ddesc.custom_minimum_size = Vector2(640, 34)
	vb.add_child(ddesc)
	dbtn.item_selected.connect(func(idx: int) -> void:
		AudioManager.set_difficolta(idx)
		ddesc.text = AudioManager.DIFFICOLTA_DESCR[idx]
		AudioManager.play_sfx("ui_click"))

	vb.add_child(_separatore())

	# Rigioca tutorial (ricomincia dalla caverna).
	var tut: Button = Button.new()
	tut.text = "Rigioca il tutorial"
	tut.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		SaveSystem.reset_run()
		get_tree().paused = false
		get_tree().change_scene_to_file(GAME_SCENE))
	vb.add_child(tut)

	var chiudi: Button = Button.new()
	chiudi.text = "Chiudi"
	chiudi.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		_chiudi())
	vb.add_child(chiudi)
	chiudi.grab_focus()


func _riga_slider(parent: VBoxContainer, nome: String, valore: float, cb: Callable) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl: Label = _lbl(nome)
	lbl.custom_minimum_size = Vector2(120, 0)
	row.add_child(lbl)
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valore
	s.custom_minimum_size = Vector2(280, 0)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var val: Label = _lbl("%d%%" % int(round(valore * 100.0)))
	val.custom_minimum_size = Vector2(54, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	s.value_changed.connect(func(v: float) -> void:
		val.text = "%d%%" % int(round(v * 100.0))
		cb.call(v))
	parent.add_child(row)


func _lbl(testo: String) -> Label:
	var l: Label = Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.9, 0.84, 0.7))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _separatore() -> ColorRect:
	var sep: ColorRect = ColorRect.new()
	sep.color = Color(0.5, 0.38, 0.22, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _chiudi() -> void:
	chiuso.emit()
	queue_free()
