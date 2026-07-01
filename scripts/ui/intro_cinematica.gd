extends CanvasLayer

# Intro cinematica (cold open al lancio): montaggio di "beat" — sfondo con lento
# Ken Burns + narrazione dissolta — dalle pitture rupestri all'era mitica, fino
# allo sfondo del menu (che porta gia' il titolo). Skippabile con un tasto/clic.
# Emette `finita` e si autolibera, rivelando il menu sottostante in crossfade.
signal finita

const BEATS: Array[Dictionary] = [
	{
		"img": "res://Assets/art/backgrounds/era1_pitture_intro.png",
		"testo": "Prima delle ere, prima dei nomi,\nun popolo si destò nel buio.",
		"dur": 4.4,
	},
	{
		"img": "res://Assets/art/backgrounds/era2_citta.png",
		"testo": "Tu sei lo Spirito che lo guida.\nOgni scelta attraversa i secoli.",
		"dur": 4.4,
	},
	{
		"img": "res://Assets/art/ui/main_menu_bg.png",
		"testo": "Il loro destino è nelle tue mani.",
		"dur": 3.4,
	},
]

var _root: ColorRect = null   # fondale nero + contenitore per il crossfade finale
var _immagine: TextureRect = null
var _scrim: TextureRect = null
var _narr: Label = null
var _skip: bool = false
var _finito: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_costruisci()
	AudioManager.play_music_id("era1")
	_sequenza()


func _input(event: InputEvent) -> void:
	if _finito:
		return
	var salta: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if salta:
		get_viewport().set_input_as_handled()
		_skip = true


func _costruisci() -> void:
	# _root È il fondale nero (un ColorRect copre sempre, anche dietro gli angoli
	# trasparenti di certi sfondi) e fa da contenitore per il crossfade finale.
	_root = ColorRect.new()
	_root.color = Color(0, 0, 0, 1)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # blocca il menu sotto
	add_child(_root)

	_immagine = TextureRect.new()
	_immagine.set_anchors_preset(Control.PRESET_FULL_RECT)
	_immagine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# SCALE riempie sempre l'intero rect (niente gap: alcuni sfondi sono piccoli/di
	# proporzioni diverse). La lieve distorsione è invisibile sotto scrim + Ken Burns.
	_immagine.stretch_mode = TextureRect.STRETCH_SCALE
	_immagine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_immagine.modulate.a = 0.0
	_root.add_child(_immagine)

	_scrim = TextureRect.new()
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.texture = _gradiente_basso()
	_root.add_child(_scrim)

	_narr = Label.new()
	_narr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_narr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narr.anchor_left = 0.5
	_narr.anchor_right = 0.5
	_narr.anchor_top = 1.0
	_narr.anchor_bottom = 1.0
	_narr.offset_left = -560.0
	_narr.offset_right = 560.0
	_narr.offset_top = -190.0
	_narr.offset_bottom = -70.0
	_narr.add_theme_font_size_override("font_size", 30)
	_narr.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	_narr.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_narr.add_theme_constant_override("outline_size", 6)
	_narr.add_theme_constant_override("line_spacing", 8)
	var cinzel: String = "res://Assets/fonts/Cinzel.ttf"
	if ResourceLoader.exists(cinzel):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel)
		fv.variation_opentype = {"wght": 500}
		_narr.add_theme_font_override("font", fv)
	_narr.modulate.a = 0.0
	_root.add_child(_narr)

	var skip: Label = Label.new()
	skip.text = "Premi un tasto per saltare"
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.anchor_top = 1.0
	skip.anchor_bottom = 1.0
	skip.offset_left = -300.0
	skip.offset_right = -24.0
	skip.offset_top = -40.0
	skip.offset_bottom = -14.0
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.add_theme_font_size_override("font_size", 15)
	skip.add_theme_color_override("font_color", Color(0.7, 0.66, 0.58, 0.7))
	skip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	skip.add_theme_constant_override("outline_size", 3)
	skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(skip)


func _gradiente_basso() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.9)])
	grad.offsets = PackedFloat32Array([0.42, 0.72, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 16
	tex.height = 256
	return tex


func _sequenza() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_immagine.pivot_offset = vp * 0.5
	for i in BEATS.size():
		if _skip:
			break
		await _beat(BEATS[i])
	_fine()


func _beat(beat: Dictionary) -> void:
	# Carica lo sfondo (se manca, resta il nero -> beat "a schermo scuro").
	var path: String = beat.get("img", "")
	if path != "" and ResourceLoader.exists(path):
		_immagine.texture = load(path)
	_immagine.scale = Vector2.ONE * 1.02
	# Fade-in immagine + Ken Burns lento.
	var dur: float = float(beat.get("dur", 4.0))
	var tin: Tween = create_tween()
	tin.tween_property(_immagine, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	var kb: Tween = create_tween()
	kb.tween_property(_immagine, "scale", Vector2.ONE * 1.1, dur + 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Testo.
	_narr.text = String(beat.get("testo", ""))
	var tt: Tween = create_tween()
	tt.tween_property(_narr, "modulate:a", 1.0, 0.9).set_delay(0.5)
	await _attendi(dur)
	# Fade-out del testo prima del prossimo beat (l'immagine resta e si dissolve nel successivo).
	var tout: Tween = create_tween()
	tout.tween_property(_narr, "modulate:a", 0.0, 0.5)
	await _attendi(0.5)


func _attendi(t: float) -> void:
	# Attesa interrompibile dallo skip, accurata al frame via tempo reale. Niente
	# lambda su variabile locale (GDScript le cattura per valore -> baco di attesa infinita).
	var fine_ms: int = Time.get_ticks_msec() + int(t * 1000.0)
	while Time.get_ticks_msec() < fine_ms and not _skip:
		await get_tree().process_frame


func _fine() -> void:
	if _finito:
		return
	_finito = true
	AudioManager.play_music_id("menu")
	var t: Tween = create_tween()
	t.tween_property(_root, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	await t.finished
	finita.emit()
	queue_free()
