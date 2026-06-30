extends CanvasLayer

# Schermata epilogo cinematografica: illustrazione a tutto schermo con lento
# zoom (Ken Burns), scrim alto/basso per leggibilita', titolo Cinzel nel tono
# del finale, testo dell'epilogo in basso.
# Impostare `finale` PRIMA di add_child() (i nodi @onready si risolvono in _ready).
var finale: Finale = null

const TONI: Dictionary = {
	"fine_guerra": Color(0.9, 0.4, 0.3),
	"fine_prosperita": Color(0.95, 0.85, 0.5),
	"fine_scienza": Color(0.55, 0.8, 1.0),
	"fine_alleanza": Color(0.6, 0.9, 0.7),
	"fine_industria": Color(0.8, 0.75, 0.6),
	"fine_futura": Color(0.8, 0.6, 1.0),
}

@onready var immagine: TextureRect = $Immagine
@onready var scrim_top: TextureRect = $ScrimTop
@onready var scrim_bottom: TextureRect = $ScrimBottom
@onready var titolo_label: Label = $Titolo
@onready var testo_label: Label = $Testo
@onready var footer_label: Label = $Footer


func _ready() -> void:
	_crea_scrims()
	_stile_testi()
	if finale == null:
		titolo_label.text = "Nessun finale"
		testo_label.text = "(finale non determinato)"
		return
	titolo_label.text = finale.nome
	titolo_label.add_theme_color_override("font_color", TONI.get(finale.id, Color.WHITE))
	testo_label.text = finale.testo
	footer_label.text = "R  Ricomincia      ·      N  Nuovo Ciclo+ (%s)      ·      L  Ledger" % Ledger.eone_nome(Ledger.eone + 1)
	_badge_eone()
	_imposta_illustrazione()
	AudioManager.play_music_id("ending")
	_anima_ingresso()


func _stile_testi() -> void:
	var cinzel_path: String = "res://Assets/fonts/Cinzel.ttf"
	if ResourceLoader.exists(cinzel_path):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel_path)
		fv.variation_opentype = {"wght": 700}
		titolo_label.add_theme_font_override("font", fv)
	titolo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	titolo_label.add_theme_constant_override("shadow_offset_y", 3)
	titolo_label.add_theme_constant_override("shadow_outline_size", 10)
	testo_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.82))
	testo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	testo_label.add_theme_constant_override("outline_size", 5)
	testo_label.add_theme_constant_override("line_spacing", 7)
	_box_footer()


# Le istruzioni non sono "testo nudo" sull'illustrazione (audit AAA #5): vanno in
# un cartiglio bronzo centrato in basso, leggibile su qualunque epilogo chiaro.
# Ancore esplicite (0.5/0.5 + offset simmetrici) come Titolo/Testo della scena:
# i preset+grow su un CanvasLayer non centravano in modo affidabile.
func _box_footer() -> void:
	if footer_label.get_parent() is PanelContainer:
		return
	var box: PanelContainer = PanelContainer.new()
	box.name = "FooterBox"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.04, 0.66)
	sb.border_color = Color(0.55, 0.42, 0.24, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	box.add_theme_stylebox_override("panel", sb)
	add_child(box)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -240.0
	box.offset_right = 240.0
	box.offset_top = -94.0
	box.offset_bottom = -44.0
	# Riparentela la Label dentro al cartiglio e falle riempire l'area imbottita.
	footer_label.reparent(box)
	footer_label.custom_minimum_size = Vector2.ZERO
	footer_label.modulate = Color.WHITE
	footer_label.add_theme_color_override("font_color", Color(0.85, 0.74, 0.52))


# Se la run conclusa era già un Nuovo Ciclo+, un cartiglio in alto la celebra:
# "Eone N — <Mutatore>". Niente se è la prima vita (Ledger.eone == 0).
func _badge_eone() -> void:
	if not Ledger.in_eone():
		return
	var box: PanelContainer = PanelContainer.new()
	box.name = "BadgeEone"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.09, 0.7)
	sb.border_color = Color(0.72, 0.55, 0.95, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	box.add_theme_stylebox_override("panel", sb)
	add_child(box)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.0
	box.anchor_bottom = 0.0
	box.offset_left = -240.0
	box.offset_right = 240.0
	box.offset_top = 26.0
	box.offset_bottom = 70.0
	var lbl: Label = Label.new()
	lbl.text = "✦ %s — %s" % [Ledger.eone_nome(), Ledger.mutatore_nome()]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.8, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 4)
	var cinzel: String = "res://Assets/fonts/Cinzel.ttf"
	if ResourceLoader.exists(cinzel):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel)
		fv.variation_opentype = {"wght": 600}
		lbl.add_theme_font_override("font", fv)
	box.add_child(lbl)


func _crea_scrims() -> void:
	# Gradienti verticali: scuriscono alto (titolo) e basso (testo) senza pannelli.
	scrim_top.texture = _gradiente_verticale(
		[Color(0, 0, 0, 0.62), Color(0, 0, 0, 0.0)], [0.0, 0.32])
	scrim_bottom.texture = _gradiente_verticale(
		[Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.96)], [0.30, 0.6, 1.0])


func _gradiente_verticale(colori: Array, offsets: Array) -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray(colori)
	grad.offsets = PackedFloat32Array(offsets)
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 16
	tex.height = 256
	return tex


func _imposta_illustrazione() -> void:
	var tex: Texture2D = finale.illustrazione
	if tex == null:
		var nome: String = finale.id.trim_prefix("fine_")
		var path: String = "res://Assets/art/finali/%s.png" % nome
		if ResourceLoader.exists(path):
			tex = load(path)
	if tex == null:
		immagine.visible = false
		return
	immagine.texture = tex


func _anima_ingresso() -> void:
	# Fade dal nero + lento zoom dell'illustrazione, poi titolo e testo a cascata.
	immagine.modulate.a = 0.0
	titolo_label.modulate.a = 0.0
	testo_label.modulate.a = 0.0
	# Anima il cartiglio del footer (testo + bordo insieme), non solo la Label.
	var footer_node: CanvasItem = footer_label.get_parent() as CanvasItem
	if footer_node == null:
		footer_node = footer_label
	footer_node.modulate.a = 0.0
	var vp: Vector2 = get_viewport().get_visible_rect().size
	immagine.pivot_offset = vp * 0.5
	immagine.scale = Vector2.ONE
	var kb: Tween = create_tween()
	kb.tween_property(immagine, "scale", Vector2.ONE * 1.07, 18.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var t: Tween = create_tween()
	t.tween_property(immagine, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(titolo_label, "modulate:a", 1.0, 1.2).set_delay(0.7)
	t.parallel().tween_property(testo_label, "modulate:a", 1.0, 1.2).set_delay(1.5)
	t.parallel().tween_property(footer_node, "modulate:a", 0.95, 0.8).set_delay(2.4)
