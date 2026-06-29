extends Node

# Tema globale + infrastruttura di REDESIGN ESTETICO (vedi Docs/13-redesign-estetico.md).
#
# Look bronzo coerente per TUTTI i Button (+ font di default), così ogni finestra, menu e
# pannello modale ha lo stesso stile curato invece dei grigi di sistema. Gli override
# per-nodo (es. CallButton) mantengono comunque la priorità.
#
# INFRASTRUTTURA ASSET: questo autoload sa caricare cornici (via StyleBoxTexture) e icone
# da cartelle dedicate, con FALLBACK alla resa attuale (StyleBoxFlat) se il PNG non c'è.
# Conseguenza: appena trascini gli asset generati (prompt in Docs/08 §P8/§P9) nelle
# cartelle, il gioco li usa AUTOMATICAMENTE — nessun'altra modifica richiesta.
#
#   Assets/art/ui/    panel.png · button_normal|hover|pressed|disabled|focus.png · chip.png
#                     tooltip.png · divider.png · corner_tl|tr|bl|br.png · medallion.png
#                     medallion_glow.png · bar_frame.png · bar_fill.png · cartouche.png
#                     parchment.png · ring_select|focus|upgrade.png · plot_pad.png
#   Assets/art/icons/ stats/<stat>.png · strategie/<id>.png · risorse.png
#                     action/<nome>.png · ledger/<nome>.png · keys/<k>.png · siege/<unit>.png

const FONT_CORPO: String = "res://Assets/fonts/Alegreya.ttf"

const COL_BORDO: Color = Color(0.60, 0.44, 0.24)
const COL_BORDO_HOVER: Color = Color(0.93, 0.72, 0.38)

const UI_DIR: String = "res://Assets/art/ui/"
const ICON_DIR: String = "res://Assets/art/icons/"
const VIGNETTE_SHADER: String = "res://Assets/shaders/vignette.gdshader"
# Margini 9-slice (angoli) e padding contenuto, calibrati sui frame §P8 reali:
# panel.png ha angoli ornati ~84px; button_*.png capi ornati ~60×22.
const PANEL_PATCH: int = 84
const PANEL_CONTENT: int = 30
const BUTTON_PATCH: int = 18
const BUTTON_CONTENT: int = 12

var _tex_cache: Dictionary = {}


func _ready() -> void:
	var theme: Theme = Theme.new()
	if ResourceLoader.exists(FONT_CORPO):
		theme.default_font = load(FONT_CORPO)
	theme.default_font_size = 18

	# Pulsanti: usa le texture §8b se presenti, altrimenti lo stile bronzo a codice.
	theme.set_stylebox("normal", "Button", _button_sb("normal", Color(0.13, 0.09, 0.06, 0.95), COL_BORDO))
	theme.set_stylebox("hover", "Button", _button_sb("hover", Color(0.19, 0.13, 0.08, 0.97), COL_BORDO_HOVER))
	theme.set_stylebox("pressed", "Button", _button_sb("pressed", Color(0.10, 0.07, 0.05, 0.98), COL_BORDO_HOVER))
	theme.set_stylebox("disabled", "Button", _button_sb("disabled", Color(0.11, 0.10, 0.09, 0.55), Color(0.42, 0.37, 0.30, 0.5)))
	theme.set_stylebox("focus", "Button", _button_sb("focus", Color(0.16, 0.11, 0.07, 0.0), COL_BORDO_HOVER))
	theme.set_color("font_color", "Button", Color(0.95, 0.88, 0.68))
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.94, 0.76))
	theme.set_color("font_pressed_color", "Button", Color(0.88, 0.80, 0.60))
	theme.set_color("font_disabled_color", "Button", Color(0.58, 0.53, 0.45))

	# Tooltip coerente (texture §8d o fallback scuro bordo bronzo) invece del bianco.
	var tip: StyleBox = _tooltip_sb()
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_color", "TooltipLabel", Color(0.92, 0.86, 0.72))

	get_tree().root.theme = theme


# --- API pubblica (usata da main.gd, village_view.gd, siege.gd, ...) ---------

# Cornice pannello ORNATA (texture §8a 9-slice): SOLO per modali centrati e box
# raccolti, dove la cornice ricca sta bene. Per HUD/pannelli grandi usa panel_clean().
func panel_stylebox() -> StyleBox:
	var tex: Texture2D = ui_texture("panel")
	if tex != null:
		return _sb_texture(tex, PANEL_PATCH, PANEL_CONTENT)
	return _panel_flat_fallback()


# Pannello PULITO: cuoio scuro semi-trasparente con bordo bronzo sottile. Per i pannelli
# sempre-visibili (HUD, dialogo, barra decisione): leggibile, ordinato, non invadente —
# così il villaggio e il testo restano i protagonisti.
func panel_clean() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.094, 0.075, 0.057, 0.88)
	sb.border_color = Color(0.46, 0.35, 0.21, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 13
	sb.content_margin_bottom = 13
	sb.shadow_color = Color(0, 0, 0, 0.40)
	sb.shadow_size = 5
	return sb


# StyleBox CTA (Call-To-Action) per i pulsanti prominenti tipo `CallButton` ("Decidi") e i
# CTA modali build/upgrade: bordo bronzo acceso, angoli morbidi, ombra. Centralizza il look
# che prima era duplicato inline in main.gd. Il chiamante itera sugli stati e mantiene i propri
# override di font/outline. `hover`/`pressed`/`focus` schiariscono leggermente il fondo.
func cta_button_stylebox(stato: String) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.07, 0.94) if stato == "hover" else Color(0.12, 0.085, 0.06, 0.92)
	sb.border_color = Color(0.78, 0.55, 0.28)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	sb.set_content_margin_all(14)
	return sb


# Backing DISCRETO della card-strategia trascinabile: volutamente tenue (alpha basso) così il
# medaglione circolare resta il protagonista. Centralizza il box prima inline in draggable_item.
func card_backing_stylebox() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.45)
	sb.border_color = Color(COL_BORDO.r, COL_BORDO.g, COL_BORDO.b, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	return sb


# Chip/badge tinto (rapporti, effetti duraturi). `tinta` colora bordo/fondo nel fallback
# e fa da modulate sulla texture §8c se presente.
func chip_stylebox(tinta: Color = COL_BORDO) -> StyleBox:
	var tex: Texture2D = ui_texture("chip")
	if tex != null:
		var sb: StyleBoxTexture = _sb_texture(tex, 14, 8)
		sb.modulate_color = Color(tinta.r, tinta.g, tinta.b, 1.0)
		return sb
	var f: StyleBoxFlat = StyleBoxFlat.new()
	f.bg_color = Color(0.12, 0.09, 0.07, 0.85)
	f.border_color = Color(tinta.r, tinta.g, tinta.b, 0.7)
	f.set_border_width_all(1)
	f.set_corner_radius_all(6)
	f.content_margin_left = 8
	f.content_margin_right = 8
	f.content_margin_top = 5
	f.content_margin_bottom = 5
	return f


# Texture UI generica da Assets/art/ui/<nome>.png (cornici d'angolo, cartiglio,
# pergamena, anelli, divisori, barre, medaglione...). null se non esiste.
func ui_texture(nome: String) -> Texture2D:
	return _carica(UI_DIR + nome + ".png")


# Icona da Assets/art/icons/<categoria>/<nome>.png. null se non esiste (il chiamante
# tiene la sua resa attuale come fallback).
func icona(categoria: String, nome: String) -> Texture2D:
	return _carica(ICON_DIR + categoria + "/" + nome + ".png")


# True se esiste un medaglione-cornice per incorniciare le icone in modo coerente.
func ha_medaglione() -> bool:
	return ui_texture("medallion") != null


# Vignette cinematografica riusabile: ColorRect full-rect mouse-ignore con lo shader
# `vignette.gdshader`. Il chiamante fa `parent.add_child(...)` e puo' animare la uniform
# "tint" col tween (J12 mystery). `intensity` = alpha massima ai bordi. Fallback-safe:
# se lo shader non c'e' (build senza import) ripiega su un rettangolo trasparente (no-op,
# nessun artefatto) invece di crashare.
func crea_vignette(intensity: float = 0.36, tint: Color = Color(0, 0, 0, 1)) -> ColorRect:
	var cr: ColorRect = ColorRect.new()
	cr.color = Color(1, 1, 1, 1)  # irrilevante: lo shader sovrascrive COLOR
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load(VIGNETTE_SHADER) if ResourceLoader.exists(VIGNETTE_SHADER) else null
	if shader != null:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tint", tint)
		mat.set_shader_parameter("intensity", intensity)
		cr.material = mat
	else:
		cr.color = Color(tint.r, tint.g, tint.b, 0.0)  # nessuno shader: niente artefatti
	return cr


# Ornamenti d'angolo "tomo rilegato" (§8f) ai 4 angoli di un rettangolo (di norma lo schermo
# intero): incorniciano menu/mappa come il Ledger. Riusa corner_*.png; fallback-safe (se i PNG
# mancano non aggiunge nulla). Ritorna i TextureRect creati così il chiamante puo' animarli.
func aggiungi_cornici(parent: Node, rect: Rect2, lato: float = 160.0, alpha: float = 0.9) -> Array:
	var out: Array = []
	if ui_texture("corner_tl") == null:
		return out
	var ang: Array = [
		["corner_tl", rect.position],
		["corner_tr", Vector2(rect.end.x - lato, rect.position.y)],
		["corner_bl", Vector2(rect.position.x, rect.end.y - lato)],
		["corner_br", Vector2(rect.end.x - lato, rect.end.y - lato)],
	]
	for a in ang:
		var tex: Texture2D = ui_texture(a[0])
		if tex == null:
			continue
		var tr: TextureRect = TextureRect.new()
		tr.texture = tex
		tr.position = a[1]
		tr.size = Vector2(lato, lato)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(1, 1, 1, alpha)
		parent.add_child(tr)
		out.append(tr)
	return out


# --- Interni -----------------------------------------------------------------

func _carica(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[path] = tex
	return tex


func _sb_texture(tex: Texture2D, patch: int, content: int) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(patch)
	sb.set_content_margin_all(content)
	return sb


func _button_sb(stato: String, bg: Color, bordo: Color) -> StyleBox:
	var tex: Texture2D = ui_texture("button_" + stato)
	if tex != null:
		# Capi ornati larghi ma bordo alto/basso sottile: margini 9-slice asimmetrici.
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 60
		sb.texture_margin_right = 60
		sb.texture_margin_top = 22
		sb.texture_margin_bottom = 22
		sb.content_margin_left = 28
		sb.content_margin_right = 28
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		return sb
	return _btn_sb(bg, bordo)


func _tooltip_sb() -> StyleBox:
	var tex: Texture2D = ui_texture("tooltip")
	if tex != null:
		return _sb_texture(tex, 16, 8)
	var tip: StyleBoxFlat = _btn_sb(Color(0.08, 0.06, 0.05, 0.96), COL_BORDO)
	tip.set_content_margin_all(8)
	return tip


# Fallback identico a main.gd._stile_pannello (resa attuale dei pannelli).
func _panel_flat_fallback() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.085, 0.07, 0.84)
	sb.border_color = Color(0.5, 0.38, 0.22, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	return sb


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
