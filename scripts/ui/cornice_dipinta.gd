class_name CorniceDipinta
extends Control

# Arte "dipinta" del kit (barra del boss, banner d'ondata, cartiglio, cornice barra HP)
# disegnata in FASCE ORIZZONTALI: le fasce fisse (capi ornati, stemmi) restano in
# proporzione alla scala dell'altezza, le fasce elastiche (barre lisce) si allungano per
# riempire la larghezza.
#
# Perché non un NinePatchRect: i PNG generati stanno su tele con ampio padding trasparente
# (es. boss_bar 1280×512 con l'arte in 1079×248). Il 9-slice prendeva il padding come
# "angolo" e schiacciava l'ornamento vero in una riga sottile; qui si disegna solo il bbox
# opaco (`regione`) e i capi non si deformano mai. Le specifiche dei PNG reali stanno in
# UiStyle.SPEC_DIPINTE (vedi UiStyle.cornice_dipinta).
#
# Canale (opzionale): l'area della barra che si "riempie" (HP). `colore_riempimento` la
# colora da 0 a `frazione` SOTTO l'arte (cornici cave, es. bar_frame); `colore_maschera`
# la copre da `frazione` alla fine SOPRA l'arte (canali già dipinti, es. il rosso del boss).

var texture: Texture2D = null
var regione: Rect2 = Rect2()          # bbox opaco nella texture (px sorgente)
var fasce: Array = []                 # [[x0, x1, elastica], ...] contigue, px della regione
var canale: Rect2 = Rect2()           # area di riempimento, px della regione (vuota = nessuna)
var frazione: float = 1.0: set = set_frazione
var colore_traccia: Color = Color(0, 0, 0, 0)
var colore_riempimento: Color = Color(0, 0, 0, 0): set = set_colore_riempimento
var colore_maschera: Color = Color(0, 0, 0, 0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_frazione(v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	if is_equal_approx(v, frazione):
		return
	frazione = v
	queue_redraw()


func set_colore_riempimento(c: Color) -> void:
	if c == colore_riempimento:
		return
	colore_riempimento = c
	queue_redraw()


# Scala sorgente → schermo: l'altezza della regione riempie l'altezza del controllo.
func scala() -> float:
	if regione.size.y <= 0.0:
		return 1.0
	return size.y / regione.size.y


# Larghezza minima perché i capi non si sovrappongano, a una data altezza.
func larghezza_minima(altezza: float) -> float:
	if regione.size.y <= 0.0:
		return 0.0
	var fisso: float = 0.0
	for f in fasce:
		if not bool(f[2]):
			fisso += float(f[1]) - float(f[0])
	return fisso * altezza / regione.size.y


# Larghezze a schermo delle fasce: le fisse a scala, le elastiche si spartiscono il resto
# in proporzione alla loro larghezza sorgente. Se lo spazio non basta, tutto si comprime
# in proporzione (caso degenere: meglio un ornamento stretto che capi sovrapposti).
func _larghezze() -> Array:
	var s: float = scala()
	var fisso: float = 0.0
	var elastico_src: float = 0.0
	for f in fasce:
		var w: float = float(f[1]) - float(f[0])
		if bool(f[2]):
			elastico_src += w
		else:
			fisso += w * s
	var resto: float = size.x - fisso
	var out: Array = []
	if resto < 0.0 or elastico_src <= 0.0:
		var tot_src: float = 0.0
		for f in fasce:
			tot_src += float(f[1]) - float(f[0])
		var k: float = size.x / maxf(tot_src, 1.0)
		for f in fasce:
			out.append((float(f[1]) - float(f[0])) * (k if resto < 0.0 else s))
		return out
	for f in fasce:
		var w2: float = float(f[1]) - float(f[0])
		out.append(resto * w2 / elastico_src if bool(f[2]) else w2 * s)
	return out


# Mappa una x della regione sorgente nella x a schermo (lineare a tratti sulle fasce).
func mappa_x(src_x: float) -> float:
	var larg: Array = _larghezze()
	var dx: float = 0.0
	for i in fasce.size():
		var x0: float = float(fasce[i][0])
		var x1: float = float(fasce[i][1])
		if src_x <= x1 or i == fasce.size() - 1:
			var t: float = clampf((src_x - x0) / maxf(x1 - x0, 1.0), 0.0, 1.0)
			return dx + t * float(larg[i])
		dx += float(larg[i])
	return dx


# Un rettangolo della regione sorgente (es. il cartiglio interno) in coordinate locali.
func mappa_rect(src: Rect2) -> Rect2:
	var s: float = scala()
	var x0: float = mappa_x(src.position.x)
	var x1: float = mappa_x(src.end.x)
	return Rect2(x0, src.position.y * s, x1 - x0, src.size.y * s)


func _draw() -> void:
	if texture == null or fasce.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var ch: Rect2 = Rect2()
	var x_frac: float = 0.0
	if canale.size.x > 0.0:
		ch = mappa_rect(canale)
		x_frac = ch.position.x + ch.size.x * frazione
		if colore_traccia.a > 0.0:
			draw_rect(ch, colore_traccia)
		if colore_riempimento.a > 0.0 and frazione > 0.0:
			draw_rect(Rect2(ch.position, Vector2(x_frac - ch.position.x, ch.size.y)), colore_riempimento)
	var larg: Array = _larghezze()
	var dx: float = 0.0
	for i in fasce.size():
		var x0: float = float(fasce[i][0])
		var x1: float = float(fasce[i][1])
		var src: Rect2 = Rect2(regione.position.x + x0, regione.position.y, x1 - x0, regione.size.y)
		var w: float = float(larg[i])
		if w > 0.0:
			draw_texture_rect_region(texture, Rect2(dx, 0.0, w, size.y), src)
		dx += w
	if ch.size.x > 0.0 and colore_maschera.a > 0.0 and frazione < 1.0:
		draw_rect(Rect2(x_frac, ch.position.y, ch.end.x - x_frac, ch.size.y), colore_maschera)
