extends CanvasLayer
# Post-processing GLOBALE del gioco (autoload PostFX, Docs/20): un ColorRect a tutto schermo con
# shader (hint_screen_texture) sopra OGNI scena → vignette + grana + color-grade + aberrazione.
# Non blocca l'input (mouse_filter IGNORE). Le intensita' sono gli uniform dello shader (postfx.gdshader).
# Attivabile/spegnibile a runtime con set_attivo() (es. per screenshot puliti o preferenza utente).

const SHADER_PATH := "res://Assets/shaders/postfx.gdshader"

var _rect: ColorRect = null


func _ready() -> void:
	layer = 128   # sopra ogni altra CanvasLayer (HUD, modali, assedio, cinematiche)
	if not ResourceLoader.exists(SHADER_PATH):
		push_warning("PostFX: shader mancante, post-processing disattivo")
		return
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	_rect.material = mat
	add_child(_rect)
	# Copertura robusta a schermo pieno: dimensione esplicita dal viewport + aggiornamento a resize
	# (gli anchor da soli non bastavano: l'autoload nasce prima che la finestra sia 1920×1080).
	_adatta()
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_adatta)


func _adatta() -> void:
	if _rect == null:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	_rect.position = Vector2.ZERO
	_rect.size = vp.get_visible_rect().size


func set_attivo(v: bool) -> void:
	if _rect != null:
		_rect.visible = v


func set_parametro(nome: String, valore: float) -> void:
	if _rect != null and _rect.material is ShaderMaterial:
		(_rect.material as ShaderMaterial).set_shader_parameter(nome, valore)
