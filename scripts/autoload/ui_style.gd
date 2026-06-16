extends Node

# Tema globale: look bronzo coerente per TUTTI i Button (+ font di default), così
# ogni finestra, menu e pannello modale ha lo stesso stile curato invece dei grigi
# di sistema. Gli override per-nodo (es. CallButton) mantengono comunque la priorità.

const FONT_CORPO: String = "res://Assets/fonts/Alegreya.ttf"

const COL_BORDO: Color = Color(0.60, 0.44, 0.24)
const COL_BORDO_HOVER: Color = Color(0.93, 0.72, 0.38)


func _ready() -> void:
	var theme: Theme = Theme.new()
	if ResourceLoader.exists(FONT_CORPO):
		theme.default_font = load(FONT_CORPO)
	theme.default_font_size = 18

	theme.set_stylebox("normal", "Button", _btn_sb(Color(0.13, 0.09, 0.06, 0.95), COL_BORDO))
	theme.set_stylebox("hover", "Button", _btn_sb(Color(0.19, 0.13, 0.08, 0.97), COL_BORDO_HOVER))
	theme.set_stylebox("pressed", "Button", _btn_sb(Color(0.10, 0.07, 0.05, 0.98), COL_BORDO_HOVER))
	theme.set_stylebox("disabled", "Button", _btn_sb(Color(0.11, 0.10, 0.09, 0.55), Color(0.42, 0.37, 0.30, 0.5)))
	theme.set_stylebox("focus", "Button", _btn_sb(Color(0.16, 0.11, 0.07, 0.0), COL_BORDO_HOVER))
	theme.set_color("font_color", "Button", Color(0.95, 0.88, 0.68))
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.94, 0.76))
	theme.set_color("font_pressed_color", "Button", Color(0.88, 0.80, 0.60))
	theme.set_color("font_disabled_color", "Button", Color(0.58, 0.53, 0.45))

	# Tooltip coerente (sfondo scuro bordo bronzo) invece del bianco di sistema.
	var tip: StyleBoxFlat = _btn_sb(Color(0.08, 0.06, 0.05, 0.96), COL_BORDO)
	tip.set_content_margin_all(8)
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", Color(0.92, 0.86, 0.72))

	get_tree().root.theme = theme


func _btn_sb(bg: Color, bordo: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bordo
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	return sb
