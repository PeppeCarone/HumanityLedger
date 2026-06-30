extends CanvasLayer
class_name SiegeArena

# L'Assedio — Fase B ("le tue statistiche diventano il tuo esercito").
# Vedi Docs/11-boss-fight.md. Villaggio a sinistra (HP da Costruzione+popolazione); i
# nemici marciano da destra su 3 corsie. Schieri 4 tipi di unità sulle piazzole, ognuna
# scalata da una stat diversa; il budget di schieramento (Risorse) viene da Tesoro/Risorse.
# Le civiltà amiche (rapporto alto) mandano truppe gratis; quelle ostili rinforzano il
# nemico. Vinci sopravvivendo a tutte le ondate; "Sopraffatto" se l'HP del villaggio va
# a 0 (no game over D024: in integrazione completa si avanza comunque).
#
# Fase B = solo codice, niente boss (Fase C) e ondate complete data-driven (Fase D).
# Tutto disegnato via _draw / Control: nessun asset richiesto.

signal assedio_concluso(esito: String)   # immacolata | trionfo | fatica | sopraffatto

# Schermata d'esito per ciascun risultato (Fase F). Vinto = tutto tranne "sopraffatto".
const ESITO_INFO: Dictionary = {
	"immacolata": {
		"titolo": "DIFESA IMMACOLATA",
		"testo": "Non una pietra è caduta.\nIl nemico si è infranto sulle mura intatte.",
		"colore": Color(1.0, 0.9, 0.55)},
	"trionfo": {
		"titolo": "TRIONFO",
		"testo": "Il villaggio resiste all'assalto.\nLo spirito può attraversare l'era.",
		"colore": Color(0.95, 0.84, 0.5)},
	"fatica": {
		"titolo": "RESISTENZA A FATICA",
		"testo": "Le mura reggono, ma a caro prezzo.\nSi prosegue, provati.",
		"colore": Color(0.9, 0.78, 0.5)},
	"sopraffatto": {
		"titolo": "VILLAGGIO SOPRAFFATTO",
		"testo": "Le difese cedono, ma lo spirito sopravvive.\nSi attraversa l'era, feriti.",
		"colore": Color(0.9, 0.5, 0.45)},
}

const VILLAGGIO_X: float = 300.0
const SPAWN_X: float = 1830.0
# Assedio 2.0 (F1): UNA strada orizzontale (Docs/14). La banda va da ROAD_TOP a ROAD_BOTTOM;
# le unità si schierano in ranghi a sinistra, i nemici marciano da destra sparsi su tutta
# l'altezza. (Prima erano 3 corsie: LANE_Y/COL_X — vedi storia in Docs/11.)
const ROAD_TOP: float = 312.0
const ROAD_BOTTOM: float = 840.0
const ROAD_MID: float = 576.0
# Spawn nemici: N "file" verticali distribuite sulla banda (riempiono la larghezza).
const N_FILE_SPAWN: int = 5
# Auto-formazione (F1): i bloccatori formano il FRONTE (colonna di testa verso i nemici);
# tiratori/sciamani/totem riempiono il RETRO. riga = indice % FORM_RIGHE; nuove colonne
# arretrano verso il villaggio. Evocazione illimitata → gli indici crescono senza limite.
const FORM_RIGHE: int = 6
const FORM_Y0: float = 398.0
const FORM_DY: float = 82.0
const FRONTE_X: float = 672.0
const FRONTE_DX: float = 62.0
const RETRO_X: float = 504.0
const RETRO_DX: float = 70.0
const RETRO_X_MIN: float = 336.0   # le colonne di retro non arretrano oltre il villaggio
const BANDA_Y: float = 54.0        # tolleranza verticale d'ingaggio mischia (line-battle)
# Cartella asset dell'Assedio (tutto fallback-safe: il codice usa forme/colori finché il
# PNG non esiste). Convenzione nomi in Docs/08-asset-prompts.md §P7.
const SIEGE_DIR: String = "res://Assets/art/siege/"

# Soglia/etichette civiltà: rispecchiano main.gd (i rapporti hanno chiavi per civ_id).
const SOGLIA_RAPPORTO: int = 2
const CIV_LABELS: Dictionary = {
	"popolo_nebbie": "Popolo delle Nebbie",
	"clan_bisonte": "Clan del Bisonte",
	"impero_sole": "Impero del Sole",
	"lega_coste": "Lega delle Coste",
}

# Archetipi (meccaniche costanti). Le skin per era stanno in SKIN.
const ORDINE: Array[String] = ["tiratore", "bloccatore", "sciamano", "totem"]
const ROSTER: Dictionary = {
	"tiratore":   {"ruolo": "ranged", "costo": 4, "raggio": 250.0, "cadenza": 0.8,  "desc": "Tiro a distanza"},
	"bloccatore": {"ruolo": "blocco", "costo": 5, "raggio": 0.0,   "cadenza": 0.9,  "desc": "Blocca la corsia"},
	"sciamano":   {"ruolo": "slow",   "costo": 5, "raggio": 190.0, "cadenza": 0.0,  "desc": "Rallenta i nemici"},
	"totem":      {"ruolo": "aoe",    "costo": 7, "raggio": 230.0, "cadenza": 1.5,  "desc": "Danno ad area"},
}
const SKIN: Dictionary = {
	# Le 4 truppe sono PERSONAGGI dell'era (Docs/14): niente oggetti (no "Totem"/"Catapulta").
	# Gli archetipi-chiave (tiratore/bloccatore/sciamano/totem) restano id interni; cambia il
	# nome mostrato e l'arte. "totem" = il caster d'area (Piromante/Mago del Fuoco).
	1: {
		"tiratore":   {"nome": "Cacciatore", "colore": Color(0.55, 0.8, 0.95)},
		"bloccatore": {"nome": "Guerriero",  "colore": Color(0.78, 0.6, 0.4)},
		"sciamano":   {"nome": "Sciamano del Gelo", "colore": Color(0.62, 0.9, 0.95)},
		"totem":      {"nome": "Piromante tribale", "colore": Color(0.95, 0.55, 0.3)},
	},
	2: {
		"tiratore":   {"nome": "Arciere",    "colore": Color(0.6, 0.82, 0.95)},
		"bloccatore": {"nome": "Legionario", "colore": Color(0.82, 0.7, 0.45)},
		"sciamano":   {"nome": "Sacerdote",  "colore": Color(0.85, 0.85, 1.0)},
		"totem":      {"nome": "Mago del Fuoco", "colore": Color(0.9, 0.6, 0.35)},
	},
}

# Nome-file dell'arte per archetipo (quando diverso dall'id). Il caster d'area NON è più un
# oggetto (Totem/Catapulta) ma un PERSONAGGIO: carica `unit_caster`/`caster` (Piromante era1,
# Mago del Fuoco era2). Finché l'arte non c'è → placeholder a figura. I vecchi `unit_totem.png`
# (totem/catapulta) sono stati rimossi: superati da `unit_caster`.
const ART_UNITA: Dictionary = {"totem": "caster"}
const ASCESA_LV: int = 4   # dal Lv4 il difensore usa lo sprite "ascesa" (elite) se esiste


# Progressione per-TIPO (Docs/14 §3): Lv1→Lv5. Lv1-2/4 solo stat; Lv3 nuova abilità + nuovo
# aspetto; Lv5 ASCENSIONE (forma finale + ultimate + passivo). Le abilità si "cablano" in F2b;
# qui (F2a) sono lo stato + i tooltip + il colpo d'occhio (stelle/aspetto). Potenziare un tipo
# fa salire TUTTE le unità di quel tipo, anche già in campo.
const LV_MAX: int = 5
const ABILITA: Dictionary = {
	"tiratore": {
		"lv3": {"nome": "Freccia perforante", "desc": "I colpi trafiggono più nemici in fila."},
		"lv5": {"nome": "Pioggia di lance", "desc": "Ultimate: raffica di lance ad area (periodica).",
			"passivo": {"nome": "Mira", "desc": "Danno critico extra sui nemici già feriti."}},
	},
	"bloccatore": {
		"lv3": {"nome": "Scudo di pelli", "desc": "Riduce il danno ad area subìto dai vicini."},
		"lv5": {"nome": "Grido di guerra", "desc": "Ultimate: stordisce i nemici davanti (periodica).",
			"passivo": {"nome": "Roccia", "desc": "Rigenera lentamente i propri HP."}},
	},
	"sciamano": {
		"lv3": {"nome": "Gelo", "desc": "Rallentamento più forte e aura più ampia."},
		"lv5": {"nome": "Tempesta di ghiaccio", "desc": "Ultimate: congela i nemici vicini (periodica).",
			"passivo": {"nome": "Aura perenne", "desc": "Rallenta sempre i nemici vicini."}},
	},
	"totem": {
		"lv3": {"nome": "Brace", "desc": "Lascia fuoco a terra dove colpisce."},
		"lv5": {"nome": "Eruzione", "desc": "Ultimate: colonna di fuoco ad area (periodica).",
			"passivo": {"nome": "Calore", "desc": "Danno continuo ai nemici nell'area."}},
	},
}

var era: int = 1
var hp_villaggio_max: int = 100
var hp_villaggio: int = 100
var risorse: int = 8

var _skin: Dictionary = {}
var _alleati_civ: Array[String] = []
var _ostili_civ: Array[String] = []
var _livello: Dictionary = {"tiratore": 1, "bloccatore": 1, "sciamano": 1, "totem": 1}

var _world: Node2D = null
var _lb_top: ColorRect = null    # barre cinematografiche (letterbox) della cinematica di fase
var _lb_bot: ColorRect = null
var _ui: Control = null
var _villaggio_panel: PanelContainer = null
var _villaggio_label: Label = null
var _tex_cache: Dictionary = {}
var _enemies: Array[SiegeEnemy] = []
var _blocchi: Array[SiegeDefender] = []
var _difensori: Array[SiegeDefender] = []   # tutti i difensori (per le AoE/stun del boss)
var _boss: SiegeBoss = null
var _spawn_queue: Array = []          # [{t, hp, vel, bounty, danno, corsia}]
var _ondate: Array = []               # ondate dell'era: [{nome, spawns:[spec]}] (Fase D)
var _ondata_idx: int = -1
var _in_pausa: bool = false
var _pausa_fino: float = 0.0
var _card_panels: Dictionary = {}     # tipo -> PanelContainer
var _card_lv: Dictionary = {}         # tipo -> Label (stelle livello)
var _card_up: Dictionary = {}         # tipo -> Button (potenzia)
var _tempo: float = 0.0
var _attivo: bool = false
var _concluso: bool = false
var _in_hitstop: bool = false   # juice: evita hit-stop sovrapposti (time_scale resterebbe basso)

var _hp_fill: ColorRect = null
var _hp_label: Label = null
var _risorse_label: Label = null
var _info_label: Label = null
var _ondata_label: Label = null
var _diplo_label: Label = null
var _boss_box: Control = null
var _boss_fill: ColorRect = null
var _boss_maschera: ColorRect = null   # con boss_bar.png: copre da destra gli HP persi
var _boss_label: Label = null
var _boss_stagger_fill: ColorRect = null   # barra di TENUTA (stagger) sotto gli HP
var _vignetta_furia: ColorRect = null   # bordi rossi mentre il boss è in furia (A2)
var _vignetta_tween: Tween = null


# Chiamare PRIMA di add_child: alimenta la difesa dalle statistiche della run
# ("le tue statistiche diventano il tuo esercito", Docs/11-boss-fight.md §2).
func configura(e: int) -> void:
	era = e
	_skin = SKIN.get(e, SKIN[1])
	hp_villaggio_max = int(round((70 + GameState.get_stat("costruzione") + int(GameState.popolazione / 4.0)) * AudioManager.difficolta_villaggio() * Ledger.ng_villaggio_mult()))
	hp_villaggio = hp_villaggio_max
	risorse = 8 + int(GameState.risorse / 4.0) + int(GameState.tesoro / 22.0) + int(GameState.get_stat("popolo") / 18.0)
	_calcola_diplomazia()


func _calcola_diplomazia() -> void:
	_alleati_civ.clear()
	_ostili_civ.clear()
	for civ_id in GameState.rapporti_civilta.keys():
		var v: int = int(GameState.rapporti_civilta[civ_id])
		var nome: String = CIV_LABELS.get(civ_id, str(civ_id))
		if v >= SOGLIA_RAPPORTO:
			_alleati_civ.append(nome)
		elif v <= -SOGLIA_RAPPORTO:
			_ostili_civ.append(nome)


# --- Caricamento asset (fallback-safe) --------------------------------------

func _carica_tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[path] = tex
	return tex


# Sprite dell'era corrente: Assets/art/siege/era<N>/<nome>.png (null se assente).
func _siege_tex(nome: String) -> Texture2D:
	return _carica_tex(SIEGE_DIR + "era%d/%s.png" % [era, nome])


# Sprite del difensore: versione "ascesa" (elite) dal Lv ASCESA_LV se l'asset esiste,
# altrimenti lo sprite base. Convenzione: unit_<tipo>[_ascesa].png in era<N>/.
func _sprite_difensore(tipo: String, lv: int) -> Texture2D:
	var base_nome: String = "unit_" + str(ART_UNITA.get(tipo, tipo))
	if lv >= ASCESA_LV:
		var asc: Texture2D = _siege_tex(base_nome + "_ascesa")
		if asc != null:
			return asc
	return _siege_tex(base_nome)


# Sfondo campo: accetta campo.jpg o campo.png (null se assenti).
func _siege_bg_tex() -> Texture2D:
	var j: String = SIEGE_DIR + "era%d/campo.jpg" % era
	if ResourceLoader.exists(j):
		return _carica_tex(j)
	return _carica_tex(SIEGE_DIR + "era%d/campo.png" % era)


# Effetto/proiettile condiviso: Assets/art/siege/fx/<nome>.png.
func _fx_tex(nome: String) -> Texture2D:
	return _carica_tex(SIEGE_DIR + "fx/%s.png" % nome)


# Cornice UI dell'Assedio condivisa: Assets/art/siege/ui/<nome>.png (boss_bar, wave_banner).
func _siege_ui_tex(nome: String) -> Texture2D:
	return _carica_tex(SIEGE_DIR + "ui/%s.png" % nome)


func _ready() -> void:
	layer = 20
	if _skin.is_empty():
		_skin = SKIN[1]
	_costruisci_scena()
	_schiera_alleati()
	_prepara_ondate()
	AudioManager.play_sfx("era_transition")
	_attivo = true
	# Onboarding: spiega l'evocazione alla prima partita (resta finché non si agisce).
	if _info_label != null:
		_info_label.text = "Clicca una carta-unità ↓ per evocarla (costa monete): si schiera da sola in formazione."
		_info_label.modulate = Color.WHITE


func _process(delta: float) -> void:
	if not _attivo or _concluso:
		return
	_tempo += delta
	# Pausa di rischieramento tra le ondate: alla scadenza parte la successiva.
	if _in_pausa:
		if _tempo >= _pausa_fino:
			_lancia_prossima_ondata()
		return
	while not _spawn_queue.is_empty() and _tempo >= float(_spawn_queue[0]["t"]):
		var d: Dictionary = _spawn_queue.pop_front()
		if bool(d.get("boss", false)):
			_spawn_boss(d)
		else:
			_spawn_enemy(d)
	_pulisci_enemies()
	_aggiorna_ondata_label()
	if _boss != null and is_instance_valid(_boss):
		_aggiorna_boss_hp()
	# Ondata ripulita: o vittoria (era l'ultima) o pausa prima della prossima.
	if _spawn_queue.is_empty() and _enemies.is_empty():
		if _ondata_idx + 1 >= _ondate.size():
			_termina(_esito_vittoria())
		else:
			_in_pausa = true
			_pausa_fino = _tempo + 3.5
			_mostra_banner("Rischiera le difese…")


# --- Costruzione scena (placeholder) ---------------------------------------

func _costruisci_scena() -> void:
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_STOP   # cattura i click: niente clic al villaggio sotto
	add_child(_ui)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.06, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(bg)

	# Sfondo dipinto del campo (se presente): sopra il fondo scuro, sotto le corsie.
	var bg_tex: Texture2D = _siege_bg_tex()
	if bg_tex != null:
		var sfondo: TextureRect = TextureRect.new()
		sfondo.texture = bg_tex
		sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
		sfondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sfondo.modulate = Color(0.82, 0.82, 0.82, 1.0)   # smorzato: le corsie restano leggibili
		sfondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Aria calda che vibra sul campo (shader isolato allo sfondo, niente UI distorta).
		var hz: String = "res://Assets/shaders/heat_haze.gdshader"
		if ResourceLoader.exists(hz):
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = load(hz)
			sfondo.material = mat
		_ui.add_child(sfondo)

	# Orda lontana sull'orizzonte: silhouette di massa nemica distante per profondità.
	# Sopra lo sfondo dipinto, sotto corsie/entità. Fallback-safe (niente nodo se assente).
	var orda_tex: Texture2D = _siege_tex("orda_orizzonte")
	if orda_tex != null:
		var orda: TextureRect = TextureRect.new()
		orda.texture = orda_tex
		orda.set_anchors_preset(Control.PRESET_TOP_WIDE)
		orda.offset_top = 150.0
		orda.offset_bottom = 360.0
		orda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		orda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		orda.modulate = Color(0.5, 0.45, 0.48, 0.9)   # scura: silhouette atmosferica
		orda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(orda)

	# La strada: UNA banda larga. Con lo sfondo dipinto è solo un velo scuro (l'arte traspare);
	# senza sfondo è piena, così la pista resta leggibile sul fondo nero.
	var terra: ColorRect = ColorRect.new()
	terra.color = Color(0.10, 0.07, 0.05, 0.30) if bg_tex != null else Color(0.16, 0.12, 0.09, 0.95)
	terra.position = Vector2(VILLAGGIO_X, ROAD_TOP)
	terra.size = Vector2(SPAWN_X - VILLAGGIO_X + 40.0, ROAD_BOTTOM - ROAD_TOP)
	terra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(terra)

	# Villaggio (cancello) a sinistra: occupa tutta l'altezza utile della strada.
	var villaggio: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.1, 0.08, 0.98)
	sb.border_color = Color(0.6, 0.44, 0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	villaggio.add_theme_stylebox_override("panel", sb)
	villaggio.position = Vector2(20.0, ROAD_TOP - 8.0)
	villaggio.size = Vector2(VILLAGGIO_X - 50.0, ROAD_BOTTOM - ROAD_TOP + 16.0)
	villaggio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(villaggio)
	_villaggio_panel = villaggio
	var vlbl: Label = Label.new()
	vlbl.text = "VILLAGGIO"
	vlbl.add_theme_font_size_override("font_size", 22)
	vlbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.55))
	vlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	villaggio.add_child(vlbl)
	_villaggio_label = vlbl

	# Sprite roccaforte (se presente): rimpiazza pannello+etichetta+merli/porte a codice.
	var rocca: Texture2D = _siege_tex("roccaforte")
	if rocca != null:
		var trasp: StyleBoxFlat = StyleBoxFlat.new()
		trasp.bg_color = Color(0, 0, 0, 0)
		villaggio.add_theme_stylebox_override("panel", trasp)
		vlbl.visible = false
		var rimg: TextureRect = TextureRect.new()
		rimg.texture = rocca
		rimg.position = Vector2(0.0, ROAD_TOP - 40.0)
		rimg.size = Vector2(VILLAGGIO_X + 30.0, ROAD_BOTTOM - ROAD_TOP + 80.0)
		rimg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rimg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		rimg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(rimg)

	_crea_decoro()

	# Mondo (entità: nemici, difensori, proiettili).
	_world = Node2D.new()
	add_child(_world)

	_crea_hud()
	_crea_barra_unita()
	_avvia_ambient()

	# Parapetto in primo piano (camminamento del difensore): incornicia il campo dal basso
	# per dare profondità cinematografica. Aggiunto direttamente all'arena DOPO _world così
	# sta davanti alle entità; il rettangolo (y ~760-950) resta sopra la barra unità in basso.
	# Fallback-safe: nessun nodo se l'asset non esiste.
	var para_tex: Texture2D = _siege_tex("parapetto")
	if para_tex != null:
		var para: TextureRect = TextureRect.new()
		para.texture = para_tex
		para.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		para.offset_top = -320.0
		para.offset_bottom = -130.0
		para.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		para.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		para.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(para)


# Pulviscolo ambientale sul campo: braci (Era 2, notte) o polvere calda (Era 1) che
# derivano lente. Dietro le entità (procedurale, nessun asset).
func _avvia_ambient() -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(960.0, ROAD_MID)
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(920.0, (ROAD_BOTTOM - ROAD_TOP) * 0.5)
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.texture = _disc_texture()
	var ramp: Gradient = Gradient.new()
	if era >= 2:
		p.amount = 28
		p.direction = Vector2(-0.2, -1.0)
		p.spread = 30.0
		p.gravity = Vector2(6.0, -20.0)
		p.initial_velocity_min = 8.0
		p.initial_velocity_max = 24.0
		p.scale_amount_min = 0.08
		p.scale_amount_max = 0.26
		ramp.colors = PackedColorArray([Color(1.0, 0.7, 0.32, 0.0),
			Color(1.0, 0.66, 0.3, 0.8), Color(0.7, 0.25, 0.1, 0.0)])
		ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	else:
		p.amount = 22
		p.direction = Vector2(1.0, -0.25)
		p.spread = 24.0
		p.gravity = Vector2(3.0, -5.0)
		p.initial_velocity_min = 5.0
		p.initial_velocity_max = 15.0
		p.scale_amount_min = 0.16
		p.scale_amount_max = 0.5
		ramp.colors = PackedColorArray([Color(0.82, 0.74, 0.6, 0.0),
			Color(0.82, 0.76, 0.64, 0.32), Color(0.7, 0.66, 0.6, 0.0)])
		ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = ramp
	_world.add_child(p)
	_world.move_child(p, 0)   # dietro le entità


# Decoro del campo (tutto in _ui, sotto le entità): bordi della strada in bronzo, chevron
# che indicano il verso d'avanzata, lato spawn, e il villaggio fortificato a sinistra.
func _crea_decoro() -> void:
	var ha_campo: bool = _siege_bg_tex() != null
	# Col campo dipinto i bordi si fanno bronzo (definiscono la pista senza coprirla).
	var bordo: Color = Color(0.55, 0.42, 0.26, 0.5) if ha_campo else Color(0.3, 0.22, 0.14, 0.7)
	var chev: Color = Color(0.42, 0.32, 0.2, 0.2)
	# Bordo superiore e inferiore della strada.
	for y in [ROAD_TOP, ROAD_BOTTOM]:
		var linea: ColorRect = ColorRect.new()
		linea.color = bordo
		linea.position = Vector2(VILLAGGIO_X - 16.0, y - 1.0)
		linea.size = Vector2(SPAWN_X - VILLAGGIO_X + 56.0, 2.0)
		linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(linea)
	# Chevron su alcune file lungo la banda: verso d'avanzata dei nemici (→ villaggio).
	var righe_chev: int = 4
	for r in range(righe_chev):
		var ty: float = lerpf(ROAD_TOP + 60.0, ROAD_BOTTOM - 60.0, float(r) / float(righe_chev - 1))
		var x: float = SPAWN_X - 80.0
		while x > VILLAGGIO_X + 150.0:
			_ui.add_child(_chevron(x, ty, chev))
			x -= 140.0

	# Lato spawn (destra): da dove entrano i nemici.
	var spawn: ColorRect = ColorRect.new()
	spawn.color = Color(0.6, 0.28, 0.24, 0.4)
	spawn.position = Vector2(SPAWN_X + 8.0, ROAD_TOP)
	spawn.size = Vector2(5.0, ROAD_BOTTOM - ROAD_TOP)
	spawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(spawn)

	# Villaggio fortificato a codice solo se non c'è lo sprite roccaforte.
	if _siege_tex("roccaforte") == null:
		_decoro_villaggio()


# Merli in cima + porte lungo il muro con architrave — fallback senza sprite roccaforte.
func _decoro_villaggio() -> void:
	var top: float = ROAD_TOP - 8.0
	var left: float = 20.0
	var right: float = VILLAGGIO_X - 30.0
	var pietra: Color = Color(0.18, 0.14, 0.1, 1.0)
	var mx: float = left
	while mx < right - 4.0:
		var merlo: ColorRect = ColorRect.new()
		merlo.color = pietra
		merlo.position = Vector2(mx, top - 18.0)
		merlo.size = Vector2(15.0, 18.0)
		merlo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(merlo)
		mx += 26.0
	# Qualche porta distribuita sull'altezza del muro.
	var porte: int = 4
	for i in range(porte):
		var y: float = lerpf(ROAD_TOP + 60.0, ROAD_BOTTOM - 60.0, float(i) / float(porte - 1))
		var porta: ColorRect = ColorRect.new()
		porta.color = Color(0.05, 0.035, 0.03, 1.0)
		porta.position = Vector2(right - 22.0, y - 22.0)
		porta.size = Vector2(28.0, 44.0)
		porta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(porta)
		var lintello: ColorRect = ColorRect.new()
		lintello.color = Color(0.5, 0.38, 0.22, 0.9)
		lintello.position = Vector2(right - 24.0, y - 26.0)
		lintello.size = Vector2(32.0, 4.0)
		lintello.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(lintello)


func _chevron(x: float, y: float, col: Color) -> Line2D:
	var l: Line2D = Line2D.new()
	l.points = PackedVector2Array([Vector2(x, y - 9.0), Vector2(x - 13.0, y), Vector2(x, y + 9.0)])
	l.width = 2.0
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	return l


func _crea_hud() -> void:
	var titolo: Label = Label.new()
	titolo.text = "L'ASSEDIO — Difendi il villaggio"
	titolo.add_theme_font_size_override("font_size", 30)
	titolo.add_theme_color_override("font_color", Color(0.93, 0.82, 0.5))
	titolo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	titolo.add_theme_constant_override("outline_size", 5)
	titolo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titolo.offset_top = 18.0
	titolo.offset_bottom = 56.0
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(titolo)

	# Riga diplomazia (alleati/ostili dai rapporti) sotto il titolo.
	_diplo_label = Label.new()
	_diplo_label.add_theme_font_size_override("font_size", 16)
	_diplo_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.62))
	_diplo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_diplo_label.add_theme_constant_override("outline_size", 3)
	_diplo_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_diplo_label.offset_top = 56.0
	_diplo_label.offset_bottom = 80.0
	_diplo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_diplo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_diplo_label)

	# Barra HP villaggio (in alto a sinistra).
	var cornice: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	sb.border_color = Color(0.6, 0.44, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	cornice.add_theme_stylebox_override("panel", sb)
	cornice.position = Vector2(40.0, 92.0)
	cornice.size = Vector2(360.0, 60.0)
	cornice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(cornice)
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	cornice.add_child(vb)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 17)
	_hp_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.72))
	vb.add_child(_hp_label)
	var track: ColorRect = ColorRect.new()
	track.color = Color(0.2, 0.12, 0.12, 0.9)
	track.custom_minimum_size = Vector2(330.0, 18.0)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(track)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.8, 0.32, 0.3)
	_hp_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_hp_fill)
	_decora_barra(track)

	# Risorse + ondata (in alto a destra).
	_risorse_label = Label.new()
	_risorse_label.add_theme_font_size_override("font_size", 22)
	_risorse_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.5))
	_risorse_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_risorse_label.add_theme_constant_override("outline_size", 4)
	_risorse_label.position = Vector2(1480.0, 96.0)
	_risorse_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_risorse_label)
	_ondata_label = Label.new()
	_ondata_label.add_theme_font_size_override("font_size", 16)
	_ondata_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.6))
	_ondata_label.position = Vector2(1480.0, 132.0)
	_ondata_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_ondata_label)

	# Suggerimento + messaggi transitori.
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 18)
	_info_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.66))
	_info_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_info_label.add_theme_constant_override("outline_size", 4)
	_info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_info_label.offset_top = -210.0   # sopra la barra-unità (più alta con livello+potenzia)
	_info_label.offset_bottom = -178.0
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_info_label)

	_aggiorna_hp()
	_aggiorna_risorse()
	_aggiorna_ondata_label()
	_aggiorna_diplo()


# --- Barra di selezione delle unità ----------------------------------------

func _crea_barra_unita() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -172.0
	bar.offset_bottom = -14.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(bar)

	for tipo in ORDINE:
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(208.0, 150.0)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.tooltip_text = _tooltip_unita(tipo)   # livello + stat reali + sblocchi
		card.add_theme_stylebox_override("panel", _card_style(false, true))
		var t: String = tipo
		# Clic sul corpo della carta = EVOCA (il pulsante Potenzia, figlio, intercetta i suoi clic).
		card.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				_evoca(t))
		var cvb: VBoxContainer = VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 1)
		cvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cvb)
		# Riga nome + stelle livello.
		var nl: Label = Label.new()
		nl.text = _skin[tipo]["nome"]
		nl.add_theme_font_size_override("font_size", 18)
		nl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.62))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(nl)
		var lv: Label = Label.new()
		lv.add_theme_font_size_override("font_size", 14)
		lv.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(lv)
		_card_lv[tipo] = lv
		var ic: Texture2D = UiStyle.icona("siege", str(ART_UNITA.get(tipo, tipo)))
		if ic != null:
			var iw: TextureRect = TextureRect.new()
			iw.texture = ic
			iw.custom_minimum_size = Vector2(0.0, 28.0)
			iw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			iw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			iw.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cvb.add_child(iw)
		var dl: Label = Label.new()
		dl.text = ROSTER[tipo]["desc"]
		dl.add_theme_font_size_override("font_size", 12)
		dl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.62))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(dl)
		var col: Label = Label.new()
		col.text = "Evoca · %d ⛃" % int(ROSTER[tipo]["costo"])
		col.add_theme_font_size_override("font_size", 14)
		col.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45))
		col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvb.add_child(col)
		# Pulsante POTENZIA (sale di livello l'intero tipo). Intercetta il proprio clic.
		var up: Button = Button.new()
		up.focus_mode = Control.FOCUS_NONE
		up.add_theme_font_size_override("font_size", 13)
		up.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		up.tooltip_text = "Potenzia tutto il tipo (sale di livello: stat, abilità a Lv3, ascensione a Lv5)"
		up.pressed.connect(func() -> void: _potenzia(t))
		cvb.add_child(up)
		_card_up[tipo] = up
		bar.add_child(card)
		_card_panels[tipo] = card

	_aggiorna_cards()


# Evoca un'unità del tipo dato (clic sulla carta): costa monete, si auto-schiera in formazione.
# Evocazione ILLIMITATA finché hai monete (Docs/14 §2). Niente piazzole.
func _evoca(tipo: String) -> void:
	if _concluso:
		return
	var costo: int = int(ROSTER[tipo]["costo"])
	if risorse < costo:
		_flash_info("Monete insufficienti per %s" % _skin[tipo]["nome"])
		AudioManager.play_sfx("stat_down")
		return
	risorse -= costo
	_aggiorna_risorse()
	_piazza(tipo, false)
	AudioManager.play_sfx("quest_complete")


# Ridispone TUTTE le unità di una categoria ("fronte" = bloccatori, "retro" = supporto) così
# da COPRIRE l'altezza della strada (Docs/14 §1): riempie la colonna di testa spargendo le
# unità su tutta la banda, poi arretra di colonna. Ogni unità raggiunge il suo posto
# camminando (vai_a). Chiamata a ogni evocazione → la linea si riforma e resta coperta.
func _ridisponi(categoria: String) -> void:
	var lista: Array[SiegeDefender] = []
	for d in _difensori:
		if not is_instance_valid(d) or not d.vivo():
			continue
		var cat: String = "fronte" if d.ruolo == "blocco" else "retro"
		if cat == categoria:
			lista.append(d)
	var n: int = lista.size()
	if n == 0:
		return
	var cols: int = int(ceil(float(n) / float(FORM_RIGHE)))
	var x0: float = FRONTE_X if categoria == "fronte" else RETRO_X
	var dx: float = FRONTE_DX if categoria == "fronte" else RETRO_DX
	var y_top: float = FORM_Y0
	var y_bot: float = FORM_Y0 + float(FORM_RIGHE - 1) * FORM_DY
	var idx: int = 0
	for c in range(cols):
		var cnt_c: int = mini(FORM_RIGHE, n - c * FORM_RIGHE)
		var x: float = x0 - float(c) * dx
		if categoria == "retro":
			x = maxf(RETRO_X_MIN, x)
		for r in range(cnt_c):
			var y: float = (y_top + y_bot) * 0.5 if cnt_c == 1 else lerpf(y_top, y_bot, float(r) / float(cnt_c - 1))
			lista[idx].vai_a(Vector2(x, y), true)
			idx += 1


func _aggiorna_cards() -> void:
	for tipo in _card_panels.keys():
		var lv: int = int(_livello[tipo])
		var asceso: bool = lv >= LV_MAX
		var ok_evoca: bool = risorse >= int(ROSTER[tipo]["costo"])
		var card: PanelContainer = _card_panels[tipo]
		card.add_theme_stylebox_override("panel", _card_style(asceso, ok_evoca))
		card.tooltip_text = _tooltip_unita(tipo)
		if _card_lv.has(tipo):
			_card_lv[tipo].text = _stelle(lv)
		if _card_up.has(tipo):
			var btn: Button = _card_up[tipo]
			if asceso:
				btn.text = "ASCESO ✦"
				btn.disabled = true
			else:
				var c: int = _costo_upgrade(tipo, lv)
				btn.text = "⬆ Lv%d · %d ⛃" % [lv + 1, c]
				btn.disabled = risorse < c


# Stato della carta: highlight dorato per il tipo asceso (Lv5); smorzata se non evocabile.
func _card_style(asceso: bool, accessibile: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.13, 0.08, 0.96) if asceso else Color(0.1, 0.08, 0.07, 0.9)
	sb.border_color = Color(1.0, 0.84, 0.45) if asceso else Color(0.5, 0.38, 0.24)
	sb.set_border_width_all(3 if asceso else 2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	if not accessibile:
		sb.bg_color = Color(0.08, 0.06, 0.05, 0.85)
		sb.border_color = Color(0.4, 0.3, 0.22) if not asceso else Color(0.7, 0.56, 0.32)
	return sb


# Stelle del livello per la carta: piene = livello raggiunto.
func _stelle(lv: int) -> String:
	var s: String = ""
	for i in range(LV_MAX):
		s += "★" if i < lv else "☆"
	return s


# Costo per salire dal livello `lv` al successivo (crescente; permanente per il tipo).
func _costo_upgrade(tipo: String, lv: int) -> int:
	return int(round(float(ROSTER[tipo]["costo"]) * (2.5 + 1.4 * float(lv - 1))))


# Moltiplicatore stat per livello (+22% per livello → Lv5 ≈ +88%).
func _lv_mult(lv: int) -> float:
	return 1.0 + 0.22 * float(lv - 1)


# Potenzia un TIPO: sale di livello (stat su; Lv3 abilità, Lv5 ascensione). Tutte le unità
# di quel tipo già in campo salgono con lui (Docs/14 §3, progressione per-tipo).
func _potenzia(tipo: String) -> void:
	if _concluso:
		return
	var lv: int = int(_livello[tipo])
	if lv >= LV_MAX:
		_flash_info("%s è già all'ascensione (Lv%d)" % [_skin[tipo]["nome"], LV_MAX])
		return
	var costo: int = _costo_upgrade(tipo, lv)
	if risorse < costo:
		_flash_info("Monete insufficienti: potenziare %s costa %d" % [_skin[tipo]["nome"], costo])
		AudioManager.play_sfx("stat_down")
		return
	risorse -= costo
	var nuovo: int = lv + 1
	_livello[tipo] = nuovo
	# Tutte le unità del tipo già schierate salgono di livello (stat + aspetto).
	for d in _difensori:
		if is_instance_valid(d) and d.tipo == tipo:
			_ristat_difensore(d, tipo)
			_pulse_levelup(d)
	_aggiorna_risorse()
	_aggiorna_cards()
	# Callout alle soglie: Lv3 abilità, Lv5 ascensione (più enfatico).
	if nuovo == 3:
		_flash_info("%s — %s SBLOCCATA!" % [_skin[tipo]["nome"].to_upper(), str(ABILITA[tipo]["lv3"]["nome"])])
		AudioManager.play_sfx("ledger_unlock")
	elif nuovo >= LV_MAX:
		_flash_info("ASCENSIONE! %s: %s + %s" % [_skin[tipo]["nome"].to_upper(),
			str(ABILITA[tipo]["lv5"]["nome"]), str(ABILITA[tipo]["lv5"]["passivo"]["nome"])])
		AudioManager.play_sfx("quest_complete")
		scuoti_forte()
	else:
		_flash_info("%s sale a Lv%d" % [_skin[tipo]["nome"], nuovo])
		AudioManager.play_sfx("quest_complete")


# Ri-applica le stat scalate dal livello corrente a un difensore già in campo.
func _ristat_difensore(d: SiegeDefender, tipo: String) -> void:
	var lv: int = int(_livello[tipo])
	var s: Dictionary = _stat_unita(tipo)
	d.danno = int(s["danno"])
	d.raggio_tiro = float(ROSTER[tipo]["raggio"]) * (1.0 + 0.10 * float(lv - 1))
	d.cadenza = maxf(0.25, float(ROSTER[tipo]["cadenza"]) * (1.0 - 0.08 * float(lv - 1)))
	match tipo:
		"bloccatore":
			var nuovo_max: int = int(s["hp"])
			var delta: int = nuovo_max - d.hp_max
			d.hp_max = nuovo_max
			if delta > 0:
				d.hp = mini(d.hp_max, d.hp + delta)   # il level-up cura della quota guadagnata
		"sciamano":
			d.slow_fattore = float(s["slow"])
		"totem":
			d.aoe_raggio = float(s["aoe"])
	d.livello = lv
	d.sprite = _sprite_difensore(tipo, lv)   # swap a/da "ascesa" al cambio livello
	d.queue_redraw()


# Lampo dorato + sobbalzo su un'unità che sale di livello.
func _pulse_levelup(d: Node2D) -> void:
	if not is_instance_valid(d):
		return
	d.modulate = Color(1.6, 1.35, 0.8)
	var t: Tween = create_tween()
	t.tween_property(d, "modulate", Color.WHITE, 0.4)
	_morte_poof(d.global_position, Color(1.0, 0.88, 0.45))


# --- Ondate / nemici --------------------------------------------------------

# Profilo di combattimento per creatura (moltiplica i valori-base dell'ondata) + ABILITÀ
# (Fase F3): comportamento distinto, non solo estetica. raggio = dimensione a schermo,
# colore = tinta del placeholder. Abilità: caricatore (scatti), scudo (assorbe N danni),
# evocatore (chiama minion), risanatore (cura i vicini). risorge = si rialza una volta.
const CREATURE_PROFILI: Dictionary = {
	# Era 1 — bestie e tribù del Paleolitico.
	"iena":      {"hp": 0.70, "vel": 1.50, "danno": 0.85, "bounty": 0, "raggio": 16.0},  # veloce, fragile
	"cinghiale": {"hp": 0.90, "vel": 1.35, "danno": 1.15, "bounty": 0, "raggio": 19.0, "caricatore": true},
	"orso":      {"hp": 1.45, "vel": 0.70, "danno": 1.35, "bounty": 1, "raggio": 27.0},  # tank lento
	"bruto":     {"hp": 1.20, "vel": 0.85, "danno": 1.10, "bounty": 1, "raggio": 24.0, "scudo": 34, "colore": Color(0.5, 0.6, 0.72)},
	"guaritore": {"hp": 0.85, "vel": 1.00, "danno": 0.60, "bounty": 2, "raggio": 18.0, "risanatore": true, "colore": Color(0.5, 0.8, 0.55)},
	"stregone":  {"hp": 0.95, "vel": 0.90, "danno": 0.70, "bounty": 2, "raggio": 20.0, "evocatore": true, "colore": Color(0.62, 0.46, 0.82)},
	# Era 2 — orde del Regno Mitico.
	"predone":   {"hp": 1.00, "vel": 1.15, "danno": 1.00, "bounty": 0, "raggio": 18.0, "caricatore": true},
	"scheletro": {"hp": 0.80, "vel": 1.00, "danno": 0.90, "bounty": 0, "raggio": 18.0, "risorge": true},
	"minotauro": {"hp": 1.40, "vel": 0.75, "danno": 1.60, "bounty": 1, "raggio": 27.0},  # colpitore pesante
	"golem":     {"hp": 1.60, "vel": 0.55, "danno": 1.15, "bounty": 2, "raggio": 28.0, "armatura": 3},
	"scudiero":  {"hp": 1.15, "vel": 0.90, "danno": 1.05, "bounty": 1, "raggio": 22.0, "scudo": 42, "colore": Color(0.55, 0.62, 0.74)},
	"sciamano_oscuro": {"hp": 0.90, "vel": 1.00, "danno": 0.70, "bounty": 2, "raggio": 19.0, "risanatore": true, "colore": Color(0.5, 0.82, 0.6)},
	"negromante": {"hp": 0.95, "vel": 0.85, "danno": 0.80, "bounty": 2, "raggio": 20.0, "evocatore": true, "colore": Color(0.6, 0.45, 0.82)},
	# Minion evocati (comune alle ere): deboli e veloci, niente bounty.
	"minion":    {"hp": 1.00, "vel": 1.25, "danno": 1.00, "bounty": 0, "raggio": 12.0, "colore": Color(0.7, 0.55, 0.5)},
}

# Ondate "normali" per era: w1, w2, w4, w5 (la w3 è il MINI-BOSS, la w6 il BOSS). Ogni
# descrittore: nome, n nemici, stat base, gap, e le creature mescolate (con le loro abilità).
const ONDATE_NORMALI: Dictionary = {
	1: [
		{"nome": "Il branco si avvicina", "n": 7,  "hp": 24, "vel": 77.0, "danno": 10, "bounty": 2, "gap": 0.66, "cr": ["iena", "cinghiale"]},
		{"nome": "La mandria carica",     "n": 10, "hp": 33, "vel": 87.0, "danno": 11, "bounty": 2, "gap": 0.52, "cr": ["cinghiale", "iena", "bruto"]},
		{"nome": "Pelli, ossa e canti",   "n": 10, "hp": 46, "vel": 75.0, "danno": 13, "bounty": 3, "gap": 0.60, "cr": ["bruto", "guaritore", "cinghiale"]},
		{"nome": "Le grandi bestie",      "n": 11, "hp": 62, "vel": 67.0, "danno": 16, "bounty": 3, "gap": 0.64, "cr": ["orso", "stregone", "cinghiale"]},
	],
	2: [
		{"nome": "I predoni all'orizzonte", "n": 7,  "hp": 28, "vel": 82.0, "danno": 11, "bounty": 2, "gap": 0.66, "cr": ["predone", "scheletro"]},
		{"nome": "Acciaio e razzia",        "n": 10, "hp": 38, "vel": 90.0, "danno": 12, "bounty": 2, "gap": 0.52, "cr": ["predone", "scudiero", "scheletro"]},
		{"nome": "I riti oscuri",           "n": 10, "hp": 50, "vel": 76.0, "danno": 14, "bounty": 3, "gap": 0.60, "cr": ["scudiero", "sciamano_oscuro", "scheletro"]},
		{"nome": "I colossi di pietra",     "n": 11, "hp": 72, "vel": 62.0, "danno": 18, "bounty": 3, "gap": 0.64, "cr": ["golem", "negromante", "minotauro"]},
	],
}

# Mini-boss dell'ondata 3 (creatura intermedia, mini-meccanica = EVOCA minion). Sprite
# opzionale enemy_<creatura>.png; fallback al cerchione placeholder.
const MINI_BOSS: Dictionary = {
	1: {"nome": "Lo Stregone della Tribù", "creatura": "stregone_capo", "hp": 280, "vel": 40.0,
		"danno": 16, "bounty": 10, "raggio": 44.0, "armatura": 2, "scudo": 70,
		"colore": Color(0.62, 0.4, 0.85), "scorta": ["iena", "cinghiale"]},
	2: {"nome": "Il Tessitore d'Ossa", "creatura": "tessitore", "hp": 340, "vel": 38.0,
		"danno": 18, "bounty": 11, "raggio": 46.0, "armatura": 3, "scudo": 95,
		"colore": Color(0.6, 0.55, 0.72), "scorta": ["scheletro", "predone"]},
}

# Fase F3: 6 ondate dinamiche. w1-w2 leggere → w3 MINI-BOSS → w4-w5 con nemici-abilità →
# w6 BOSS finale. Scala con era e civiltà ostili. (Balance fine alla F5.)
func _prepara_ondate() -> void:
	_ondate.clear()
	_ondata_idx = -1
	# Difficoltà (preferenza): scala la minaccia piegandola in `ef`. Equilibrato = ×1.0 →
	# il bilanciamento di riferimento (balance_sim) resta intatto. Il Nuovo Ciclo+ (Eone)
	# vi si moltiplica sopra: +15% minaccia per Eone (cap ×2.0), Eone 0 = ×1.0 → niente effetto.
	var ef: float = (1.0 + 0.18 * float(era - 1)) * AudioManager.difficolta_minaccia() * Ledger.ng_minaccia_mult()
	var of: float = 1.0 + 0.12 * float(_ostili_civ.size()) # rinforzo dei nemici ostili
	var extra: int = _ostili_civ.size()
	var normali: Array = ONDATE_NORMALI.get(era, ONDATE_NORMALI[1])   # 4 descrittori
	_ondate.append(_ondata_normale(normali[0], ef, of, extra))   # w1
	_ondate.append(_ondata_normale(normali[1], ef, of, extra))   # w2
	_ondate.append(_ondata_mini_boss(ef, of, extra))             # w3 MINI-BOSS
	_ondate.append(_ondata_normale(normali[2], ef, of, extra))   # w4
	_ondate.append(_ondata_normale(normali[3], ef, of, extra))   # w5
	# w6: il BOSS finale dell'era (redesign completo — evoca esercito, ultimate — in F4).
	var nome_boss: String = "Il Drago" if era >= 2 else "Il Colosso"
	# HP per-FASE (il boss ha FASI barre piene): ALTO — un giocatore che evolve le truppe ha
	# tanto DPS, il boss non deve fondersi in 2 secondi. Ogni fase è una vera battaglia.
	var boss_hp: int = int(round((1300 + 160 * float(extra)) * ef))
	_ondate.append({"nome": nome_boss, "boss": true, "spawns": [
		{"boss": true, "hp": boss_hp, "vel": 48.0, "bounty": 14, "danno": 48,
			"corsia": 2, "nome": nome_boss, "gap": 0.0}]})
	# Avvio: breve attesa, poi la prima ondata (col suo banner).
	_in_pausa = true
	_pausa_fino = _tempo + 1.4


# Costruisce un'ondata "normale" da un descrittore: n nemici (mescola le creature/abilità).
func _ondata_normale(b: Dictionary, ef: float, of: float, extra: int) -> Dictionary:
	var spawns: Array = []
	var cr: Array = b["cr"]
	for k in range(int(b["n"]) + extra):
		spawns.append({
			"hp": int(round(float(b["hp"]) * ef * of)),
			"vel": float(b["vel"]),
			"danno": int(round(float(b["danno"]) * ef)),
			"bounty": int(b["bounty"]),
			"corsia": k % N_FILE_SPAWN,
			"gap": float(b["gap"]),
			"creatura": str(cr[k % cr.size()]),
		})
	return {"nome": str(b["nome"]), "spawns": spawns}


# Costruisce l'ondata MINI-BOSS (w3): una piccola scorta che entra, poi il mini-boss
# (grosso, corazzato, EVOCA minion = la sua mini-meccanica).
func _ondata_mini_boss(ef: float, of: float, extra: int) -> Dictionary:
	var info: Dictionary = MINI_BOSS.get(era, MINI_BOSS[1])
	var spawns: Array = []
	var scorta: Array = info["scorta"]
	for k in range(4 + extra):
		spawns.append({
			"hp": int(round(28.0 * ef * of)), "vel": 80.0, "danno": 9, "bounty": 2,
			"corsia": k % N_FILE_SPAWN, "gap": 0.5, "creatura": str(scorta[k % scorta.size()]),
		})
	spawns.append({
		"hp": int(round(float(info["hp"]) * ef * of)), "vel": float(info["vel"]),
		"danno": int(info["danno"]), "bounty": int(info["bounty"]), "corsia": 2, "gap": 0.0,
		"creatura": str(info["creatura"]), "raggio": float(info["raggio"]),
		"armatura": int(info["armatura"]), "scudo": int(round(float(info["scudo"]) * ef)),
		"colore": info["colore"], "evocatore": true, "caster": true,
		"mini_boss": true, "nome": str(info["nome"]),
	})
	return {"nome": str(info["nome"]), "mini_boss": true, "spawns": spawns}


# Lancia l'ondata successiva: riempie la coda di spawn e annuncia il banner.
func _lancia_prossima_ondata() -> void:
	_in_pausa = false
	_ondata_idx += 1
	if _ondata_idx >= _ondate.size():
		return
	var w: Dictionary = _ondate[_ondata_idx]
	var t: float = _tempo + 0.7
	for s in w["spawns"]:
		var d: Dictionary = (s as Dictionary).duplicate()
		d["t"] = t
		_spawn_queue.append(d)
		t += float(s.get("gap", 0.9))
	_mostra_banner(_testo_banner(w))
	if bool(w.get("boss", false)):
		AudioManager.play_sfx("era_transition")


# Testo del banner d'ondata; con Spionaggio alto rivela la composizione (intel).
func _testo_banner(w: Dictionary) -> String:
	var n: int = _ondata_idx + 1
	var tot: int = _ondate.size()
	var testo: String = "Ondata %d / %d — %s" % [n, tot, str(w["nome"])]
	if not bool(w.get("boss", false)) and GameState.get_stat("spionaggio") >= 45:
		testo += "\n(Spionaggio: %d nemici in arrivo)" % (w["spawns"] as Array).size()
	return testo


# Y di una "fila" di spawn, distribuita sull'altezza della strada (line-battle).
func _corsia_y(c: int) -> float:
	var t: float = float(clampi(c, 0, N_FILE_SPAWN - 1)) / float(maxi(N_FILE_SPAWN - 1, 1))
	return lerpf(ROAD_TOP + 78.0, ROAD_BOTTOM - 58.0, t)


func _spawn_enemy(d: Dictionary) -> void:
	var e: SiegeEnemy = SiegeEnemy.new()
	# Profilo per-creatura: scala HP/velocità/danno e abilita armatura/risorge.
	var cr: String = str(d.get("creatura", ""))
	var prof: Dictionary = CREATURE_PROFILI.get(cr, {})
	e.hp_max = maxi(1, int(round(float(d["hp"]) * float(prof.get("hp", 1.0)))))
	e.hp = e.hp_max
	e.velocita = float(d["vel"]) * float(prof.get("vel", 1.0))
	e.bounty = int(d.get("bounty", 2)) + int(prof.get("bounty", 0))
	e.danno_villaggio = int(round(float(d.get("danno", 8)) * float(prof.get("danno", 1.0))))
	e.danno_melee = maxi(4, int(e.danno_villaggio / 2))
	e.armatura = int(d.get("armatura", prof.get("armatura", 0)))
	e.risorge = bool(prof.get("risorge", false))
	# Abilità (Fase F3): dal profilo della creatura oppure dallo spec d (mini-boss).
	e.caricatore = bool(prof.get("caricatore", false)) or bool(d.get("caricatore", false))
	e.evocatore = bool(prof.get("evocatore", false)) or bool(d.get("evocatore", false))
	e.risanatore = bool(prof.get("risanatore", false)) or bool(d.get("risanatore", false))
	e.scudo_max = int(d.get("scudo", 0)) + int(round(float(prof.get("scudo", 0)) * (1.0 + 0.15 * float(era - 1))))
	e.scudo = e.scudo_max
	e.caster = bool(d.get("caster", false))
	e.mini_boss = bool(d.get("mini_boss", false))
	e.nome = str(d.get("nome", ""))
	e.raggio = float(d["raggio"]) if d.has("raggio") else float(prof.get("raggio", 18.0))
	if prof.has("colore"):
		e.colore = prof["colore"]
	if d.has("colore"):
		e.colore = d["colore"]
	e.villaggio_x = VILLAGGIO_X
	e.corsia = int(d.get("corsia", 0))
	e.arena = self
	# Sprite per-tipo (cinghiale/orso/scheletro/…) col generico "enemy" come fallback.
	var tex: Texture2D = _siege_tex("enemy_" + cr) if cr != "" else null
	e.sprite = tex if tex != null else _siege_tex("enemy")
	_world.add_child(e)
	# Marciano da destra, sparsi su tutta l'altezza della strada (file + jitter).
	e.global_position = Vector2(SPAWN_X, _corsia_y(e.corsia) + randf_range(-16.0, 16.0))
	e.morto.connect(func(b: int) -> void: _on_enemy_morto(e, b))
	e.arrivato.connect(func(dn: int) -> void: _on_enemy_arrivato(e, dn))
	_enemies.append(e)
	if e.mini_boss:
		_flash_info("MINI-BOSS — %s" % e.nome.to_upper())
		scuoti_forte()
		AudioManager.play_sfx("era_transition")


func _on_enemy_morto(e: SiegeEnemy, bounty: int) -> void:
	_enemies.erase(e)
	risorse += bounty
	_aggiorna_risorse()
	if is_instance_valid(e):
		_morte_poof(e.global_position, e.colore)
		if e.mini_boss:
			# Caduta del mini-boss: piccolo finisher (poof+esplosione+lampo info).
			fx_esplosione(e.global_position, 130.0)
			_morte_poof(e.global_position, Color(1.0, 0.85, 0.5))
			_flash_info("%s È CADUTO!" % e.nome.to_upper())
			scuoti_forte()
			AudioManager.play_sfx("ledger_unlock")


# Evoca un minion vicino a `pos` (mini-meccanica dell'Evocatore). Cap di sicurezza per
# evitare valanghe. Il minion conta come nemico: va ucciso per chiudere l'ondata.
func spawn_minion(pos: Vector2, corsia: int) -> void:
	if not _attivo or _concluso or _enemies.size() > 40:
		return
	_spawn_enemy({"hp": 20, "vel": 100.0, "danno": 7, "bounty": 1, "corsia": corsia, "creatura": "minion"})
	if not _enemies.is_empty():
		var e: SiegeEnemy = _enemies[-1]
		if is_instance_valid(e):
			e.global_position = pos + Vector2(randf_range(18.0, 56.0), randf_range(-28.0, 28.0))
			e.scale = Vector2(0.4, 0.4)
			var t: Tween = create_tween()
			t.tween_property(e, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Cura i nemici nell'area (mini-meccanica del Risanatore), con un alone verde.
func cura_nemici_area(pos: Vector2, raggio: float, cura: int) -> void:
	for e in nemici_in_area(pos, raggio):
		if is_instance_valid(e) and e.has_method("cura"):
			e.cura(cura)
	fx_anello(pos, raggio, Color(0.5, 1.0, 0.6))


func _on_enemy_arrivato(e: SiegeEnemy, danno: int) -> void:
	_enemies.erase(e)
	hp_villaggio = maxi(0, hp_villaggio - danno)
	_aggiorna_hp()
	_scuoti()
	_flash_danno()
	AudioManager.play_sfx("stat_down")
	if hp_villaggio <= 0:
		_termina("sopraffatto")


func _pulisci_enemies() -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_enemies[i]):
			_enemies.remove_at(i)


# --- Boss (Fase C) ----------------------------------------------------------

func _spawn_boss(d: Dictionary) -> void:
	var b: SiegeBoss = SiegeBoss.new()
	# Più tosto ma non grindy: HP +12%; la finestra VULNERABILE (stagger) è la leva vera.
	b.hp_max = int(float(d.get("hp", 320)) * 1.12)
	b.hp = b.hp_max
	b.velocita = float(d.get("vel", 34.0))
	b.bounty = int(d.get("bounty", 14))
	b.danno_villaggio = int(d.get("danno", 40))
	b.danno_melee = 24
	b.armatura = 14   # incassa parte di ogni colpo: con difensori evoluti non si fonde in 2s
	b.villaggio_x = VILLAGGIO_X
	b.corsia = int(d.get("corsia", 1))
	b.raggio = 64.0
	b.arena = self
	b.legge = GameState.get_stat("legge")
	b.nome_boss = str(d.get("nome", "Il Colosso"))
	b.sprite = _siege_tex("boss")
	b.imposta_era(era)   # sceglie il kit di abilità per archetipo (Colosso vs Drago)
	# Tenuta: ~un terzo della barra HP → lo stagger è un BEAT ricorrente, non un evento unico.
	b.stagger_max = float(b.hp_max) * 0.6
	b.stagger_gain = 1.0 + float(GameState.get_stat("spionaggio")) / 80.0
	b.stagger_cambiato.connect(_on_boss_stagger)
	_world.add_child(b)
	b.global_position = Vector2(SPAWN_X - 30.0, ROAD_MID)
	b._spawn_x = float(SPAWN_X) - 30.0
	b.morto.connect(func(_bt: int) -> void: _on_boss_morto(b))
	b.arrivato.connect(func(dn: int) -> void: _on_enemy_arrivato(b, dn))
	b.furia_entrata.connect(func() -> void:
		# La 2ª fase coincide con la trasformazione (stessa soglia): la cinematica fa il resto.
		_vignetta_furia_attiva())
	b.frenesia_entrata.connect(func() -> void: cinematica_frenesia(b))
	b.trasforma_entrata.connect(func() -> void: cinematica_trasformazione(b))
	_enemies.append(b)
	_boss = b
	_crea_barra_boss(b.nome_boss)
	_boss_entrata(b)


func _boss_entrata(b: SiegeBoss) -> void:
	# Ingresso cinematico: shake + banner; la barra HP appare in dissolvenza.
	scuoti_forte()
	AudioManager.play_sfx("stat_down")
	_flash_info("%s SI AVVICINA" % b.nome_boss.to_upper())
	if _boss_box != null:
		_boss_box.modulate.a = 0.0
		var t: Tween = create_tween()
		t.tween_property(_boss_box, "modulate:a", 1.0, 0.6)


func _on_boss_morto(b: SiegeEnemy) -> void:
	_enemies.erase(b)
	risorse += 14
	_aggiorna_risorse()
	_boss = null
	if _boss_box != null and is_instance_valid(_boss_box):
		var t: Tween = create_tween()
		t.tween_property(_boss_box, "modulate:a", 0.0, 0.5)
		t.tween_callback(_boss_box.queue_free)
		_boss_box = null
		_boss_maschera = null
		_boss_fill = null
	scuoti_forte()
	AudioManager.play_sfx("ledger_unlock")
	_dissolvi_vignetta_furia()
	_finisher_boss(b)


# Finisher alla morte del boss (A3): poof maggiorato + esplosione sul punto del boss e lampo
# bianco a tutto schermo con breve hold. Niente Engine.time_scale (coerente con J13): è il
# lampo a dare il "peso" del colpo decisivo — il momento più applaudito del video.
func _finisher_boss(b: SiegeEnemy) -> void:
	var pos: Vector2 = b.global_position if is_instance_valid(b) else Vector2(900.0, 520.0)
	hitstop(0.13, 0.04)   # colpo decisivo: l'uccisione del boss "pesa"
	_morte_poof(pos, Color(1.0, 0.85, 0.5))
	_morte_poof(pos, Color(1.0, 0.6, 0.3))
	fx_esplosione(pos, 120.0)
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.85, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(flash)
	var t: Tween = create_tween()
	t.tween_property(flash, "color:a", 0.6, 0.07)
	t.tween_interval(0.06)   # breve fermo-immagine simulato (senza time_scale)
	t.tween_property(flash, "color:a", 0.0, 0.5)
	t.tween_callback(flash.queue_free)


func _crea_barra_boss(nome: String) -> void:
	if _boss_box != null and is_instance_valid(_boss_box):
		_boss_box.queue_free()
	var box: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.06, 0.92)
	sb.border_color = Color(0.7, 0.3, 0.26)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	box.add_theme_stylebox_override("panel", sb)
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = 520.0
	box.offset_right = -520.0
	box.offset_top = 90.0
	box.offset_bottom = 150.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(box)
	_boss_box = box
	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	box.add_child(vb)
	_boss_label = Label.new()
	_boss_label.text = nome
	_boss_label.add_theme_font_size_override("font_size", 18)
	_boss_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.45))
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_boss_label)
	var track: ColorRect = ColorRect.new()
	track.color = Color(0.22, 0.1, 0.1, 0.95)
	track.custom_minimum_size = Vector2(0.0, 22.0)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(track)
	_boss_fill = null
	_boss_maschera = null
	var bar_tex: Texture2D = _siege_ui_tex("boss_bar")
	if bar_tex != null:
		# Arte dedicata §P7 7k: il canale rosso è dipinto; una maschera scura nel canale
		# copre gli HP persi (da destra), lasciando visibili i capi ornati.
		track.color = Color(0, 0, 0, 0)
		var np: NinePatchRect = NinePatchRect.new()
		np.texture = bar_tex
		np.patch_margin_left = 72
		np.patch_margin_right = 72
		np.patch_margin_top = 20
		np.patch_margin_bottom = 20
		np.set_anchors_preset(Control.PRESET_FULL_RECT)
		np.offset_left = -10.0
		np.offset_right = 10.0
		np.offset_top = -14.0
		np.offset_bottom = 14.0
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(np)
		var canale: Control = Control.new()
		canale.set_anchors_preset(Control.PRESET_FULL_RECT)
		canale.offset_left = 66.0
		canale.offset_right = -66.0
		canale.offset_top = 3.0
		canale.offset_bottom = -3.0
		canale.clip_contents = true
		canale.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(canale)
		_boss_maschera = ColorRect.new()
		_boss_maschera.color = Color(0.05, 0.025, 0.03, 0.92)
		_boss_maschera.set_anchors_preset(Control.PRESET_FULL_RECT)
		_boss_maschera.anchor_left = 1.0   # pieno = nessuna copertura
		_boss_maschera.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canale.add_child(_boss_maschera)
	else:
		_boss_fill = ColorRect.new()
		_boss_fill.color = Color(0.85, 0.28, 0.24)
		_boss_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		_boss_fill.anchor_right = 1.0
		_boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(_boss_fill)
		_decora_barra(track)
	# Barra di TENUTA (stagger) sotto gli HP: i colpi la riempiono; piena → VULNERABILE.
	var st_track: ColorRect = ColorRect.new()
	st_track.color = Color(0.08, 0.12, 0.16, 0.9)
	st_track.custom_minimum_size = Vector2(0.0, 8.0)
	st_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(st_track)
	_boss_stagger_fill = ColorRect.new()
	_boss_stagger_fill.color = Color(0.5, 0.85, 1.0)
	_boss_stagger_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_boss_stagger_fill.anchor_right = 0.0
	_boss_stagger_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st_track.add_child(_boss_stagger_fill)


func _aggiorna_boss_hp() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	var frac: float = clampf(float(_boss.hp) / float(maxi(_boss.hp_max, 1)), 0.0, 1.0)
	if _boss_maschera != null and is_instance_valid(_boss_maschera):
		_boss_maschera.anchor_left = frac   # copre il canale da frac a destra
	elif _boss_fill != null and is_instance_valid(_boss_fill):
		_boss_fill.anchor_right = frac
		_boss_fill.color = Color(0.95, 0.45, 0.25) if frac <= _boss.furia_soglia else Color(0.85, 0.28, 0.24)


# Aggiorna la barra di tenuta; oro lampeggiante quando il boss è VULNERABILE.
func _on_boss_stagger(frac: float, vulnerabile: bool) -> void:
	if _boss_stagger_fill == null or not is_instance_valid(_boss_stagger_fill):
		return
	_boss_stagger_fill.anchor_right = frac
	_boss_stagger_fill.color = Color(1.0, 0.95, 0.45) if vulnerabile else Color(0.5, 0.85, 1.0)


# Callout grande quando la tenuta si spezza: è la finestra di burst da sfruttare.
func segnala_stagger(nome: String) -> void:
	_flash_info("%s È VULNERABILE — COLPISCILO!" % nome.to_upper())
	AudioManager.play_sfx("quest_complete")


# --- Boss 2.0 (Fase F4): cambio fase cinematografico + ultimate + evoca esercito ----------

# Cinematica del CAMBIO FASE al 50% HP (Docs/14 §5): breve hitstop (tempo reale, ripristina il
# time_scale qualunque esso sia — playtest incluso), poi zoom-punch sul boss + vignetta + banner.
# Lampo a tutto schermo (per i momenti grossi: trasformazione, impatti).
func _flash_schermo(col: Color, peak: float = 0.5) -> void:
	var fl: ColorRect = ColorRect.new()
	fl.color = Color(col.r, col.g, col.b, 0.0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fl)
	var t: Tween = create_tween()
	t.tween_property(fl, "color:a", peak, 0.06)
	t.tween_property(fl, "color:a", 0.0, 0.45)
	t.tween_callback(fl.queue_free)


func cinematica_trasformazione(boss: SiegeBoss, fase: int = 2) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	AudioManager.play_sfx("era_transition")
	scuoti_forte()
	_vignetta_furia_attiva()
	# 1) IL COLPO: fermo-immagine reale + LAMPO + onda d'urto sul boss (il "boom").
	hitstop(0.24, 0.05)
	await get_tree().create_timer(0.26, true, false, true).timeout
	_flash_schermo(Color(1.0, 0.86, 0.6), 0.55)
	if is_instance_valid(boss):
		fx_vfx(boss.global_position, 560.0, "shockwave", true)
		fx_esplosione(boss.global_position, 280.0)
		_burst_ember(boss.global_position, Color(1.0, 0.62, 0.3))
	scuoti_forte()
	# 2) IL CLOU: barre cinema + title-card di fase + zoom-punch FORTE e lungo sul boss.
	_cinema_letterbox(true, 0.30)
	var romano: String = "III" if fase >= 3 else "II"
	var sub: String = "FURIA FINALE" if fase >= 3 else ("L'IRA DEL DRAGO" if boss.era_boss >= 2 else "L'IRA DEL COLOSSO")
	_cinema_titolo("FASE  " + romano, sub, Color(1.0, 0.5, 0.32))
	if _world != null and is_instance_valid(_world) and is_instance_valid(boss):
		var f: Vector2 = boss.global_position
		var s: float = 1.42
		var zt: Tween = create_tween()
		zt.tween_property(_world, "scale", Vector2(s, s), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		zt.parallel().tween_property(_world, "position", f * (1.0 - s), 0.30)
		zt.tween_interval(1.2)
		zt.tween_property(_world, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)
		zt.parallel().tween_property(_world, "position", Vector2.ZERO, 0.45)
		zt.tween_callback(func() -> void: _cinema_letterbox(false, 0.35))
	else:
		var lt: Tween = create_tween()
		lt.tween_interval(1.7)
		lt.tween_callback(func() -> void: _cinema_letterbox(false, 0.35))


# Cinematica più SECCA della 3ª fase (FRENESIA, 25% HP): lampo rosso + title-card + micro
# zoom-punch. È il secondo "battito" — non ripete lo slow-mo pieno, così resta sorprendente.
func cinematica_frenesia(boss: SiegeBoss) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	AudioManager.play_sfx("stat_down")
	scuoti_forte()
	_pulsa_vignetta_furia()
	hitstop(0.12, 0.06)
	await get_tree().create_timer(0.14, true, false, true).timeout
	var fl: ColorRect = ColorRect.new()
	fl.color = Color(0.75, 0.08, 0.06, 0.0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fl)
	var ft: Tween = create_tween()
	ft.tween_property(fl, "color:a", 0.34, 0.08)
	ft.tween_property(fl, "color:a", 0.0, 0.5)
	ft.tween_callback(fl.queue_free)
	_cinema_titolo("FASE  III", "FRENESIA — l'ultimo assalto", Color(1.0, 0.36, 0.3))
	if _world != null and is_instance_valid(_world) and is_instance_valid(boss):
		var f: Vector2 = boss.global_position
		var s: float = 1.12
		var zt: Tween = create_tween()
		zt.tween_property(_world, "scale", Vector2(s, s), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		zt.parallel().tween_property(_world, "position", f * (1.0 - s), 0.16)
		zt.tween_interval(0.5)
		zt.tween_property(_world, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_SINE)
		zt.parallel().tween_property(_world, "position", Vector2.ZERO, 0.32)


# Barre nere cinematografiche (letterbox) sopra/sotto: dichiarano "momento clou". Riusate da
# entrambe le cinematiche di fase. Create una volta, poi solo animate.
func _cinema_letterbox(mostra: bool, dur: float = 0.3) -> void:
	var h: float = 118.0
	if _lb_top == null or not is_instance_valid(_lb_top):
		_lb_top = ColorRect.new()
		_lb_top.color = Color(0, 0, 0, 1)
		_lb_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lb_top.anchor_right = 1.0
		_lb_top.offset_bottom = 0.0
		_ui.add_child(_lb_top)
		_lb_bot = ColorRect.new()
		_lb_bot.color = Color(0, 0, 0, 1)
		_lb_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lb_bot.anchor_top = 1.0
		_lb_bot.anchor_right = 1.0
		_lb_bot.anchor_bottom = 1.0
		_lb_bot.offset_top = 0.0
		_ui.add_child(_lb_bot)
	var t: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_lb_top, "offset_bottom", h if mostra else 0.0, dur)
	t.tween_property(_lb_bot, "offset_top", (-h) if mostra else 0.0, dur)


# Title-card centrato del cambio fase: titolo grande + sottotitolo, dissolvenza in/out.
func _cinema_titolo(titolo: String, sotto: String, col: Color) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	var t1: Label = Label.new()
	t1.text = titolo
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 66)
	t1.add_theme_color_override("font_color", col)
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	t1.add_theme_constant_override("outline_size", 9)
	box.add_child(t1)
	var t2: Label = Label.new()
	t2.text = sotto
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 27)
	t2.add_theme_color_override("font_color", Color(0.96, 0.9, 0.82))
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	t2.add_theme_constant_override("outline_size", 5)
	box.add_child(t2)
	_ui.add_child(box)
	box.modulate = Color(1, 1, 1, 0.0)
	var t: Tween = create_tween()
	t.tween_property(box, "modulate:a", 1.0, 0.22)
	t.tween_interval(0.92)
	t.tween_property(box, "modulate:a", 0.0, 0.42)
	t.tween_callback(box.queue_free)


# Ultimate del boss (Fase F4/profondità): TELEGRAFATA e a ZONE, diversa per archetipo. Mostra
# le zone di pericolo (~1s) poi colpisce SOLO chi è dentro → è EVITABILE/mitigabile (spargi le
# difese, arretra, oppure spezza la tenuta per impedirla). `potenza` cala a ogni uso (anti-rip).
#   Colosso (Era 1): FRANA — onde sismiche davanti a sé (2 grandi zone verso il villaggio).
#   Drago (Era 2): TEMPESTA DI FUOCO — 4 zone sparse sul campo.
func boss_ultimate(era_b: int, potenza: int, origin: Vector2 = Vector2(900.0, ROAD_MID)) -> void:
	var nome: String = "TEMPESTA DI FUOCO" if era_b >= 2 else "FRANA ROVINOSA"
	_flash_info("ULTIMATE — %s!  sparpaglia le difese!" % nome)
	AudioManager.play_sfx("stat_down")
	_scuoti()
	# Zone di pericolo (telegrafate).
	var zone: Array[Vector2] = []
	var raggio: float = 175.0 if era_b >= 2 else 240.0
	var n_zone: int = 4 if era_b >= 2 else 3
	# Mira ai DIFENSORI (l'ultimate DEVE colpire, non cadere a vuoto).
	var difs: Array = difensori_in_area(Vector2(VILLAGGIO_X + 600.0, ROAD_MID), 2200.0)
	difs.shuffle()
	for d in difs:
		if d != null and is_instance_valid(d):
			zone.append(d.global_position)
		if zone.size() >= n_zone:
			break
	while zone.size() < n_zone:
		zone.append(Vector2(randf_range(VILLAGGIO_X + 120.0, VILLAGGIO_X + 720.0),
			randf_range(ROAD_TOP + 60.0, ROAD_BOTTOM - 60.0)))
	# Telegrafo: dischi rossi pulsanti per ~1s.
	var marker: Array[Node] = []
	for z in zone:
		marker.append(_telegrafo_disco(z, raggio))
	await get_tree().create_timer(1.3).timeout
	# Impatto: danno SOLO nelle zone (lo Scudo di pelli del Bloccatore Lv3 lo mitiga).
	hitstop(0.09, 0.05)   # l'ultimate "atterra" con peso
	for z in zone:
		danno_area_difensori(z, raggio, potenza)
		fx_vfx(z, raggio * 2.2, "fire_burst" if era_b >= 2 else "impatto_terra", true)
		fx_esplosione(z, raggio)
	for m in marker:
		if is_instance_valid(m):
			m.queue_free()
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 0.5, 0.2, 0.0) if era_b >= 2 else Color(0.85, 0.62, 0.32, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(flash)
	var t: Tween = create_tween()
	t.tween_property(flash, "color:a", 0.42, 0.10)
	t.tween_property(flash, "color:a", 0.0, 0.5)
	t.tween_callback(flash.queue_free)
	scuoti_forte()


# Disco rosso pulsante che telegrafa una zona dell'ultimate. Ritorna il nodo (da liberare).
func _telegrafo_disco(pos: Vector2, raggio: float) -> Node:
	var s: Sprite2D = Sprite2D.new()
	s.texture = _disc_texture()
	s.centered = true
	s.modulate = Color(0.95, 0.2, 0.15, 0.0)
	var base: float = raggio * 2.0 / 64.0
	s.scale = Vector2(base, base)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.set_loops(12)   # finito: evita "infinite loop detected" sotto time_scale accelerato (playtest)
	t.tween_property(s, "modulate:a", 0.5, 0.16)
	t.tween_property(s, "modulate:a", 0.22, 0.16)
	return s


# INTERMEZZO di cambio fase (idea utente): i nemici-add SPARISCONO (poof), poi parte la cinematica
# (il boss è invulnerabile e cresce; la barra HP si "ricarica" da sola leggendo _boss.hp). Chiamato
# da SiegeBoss._cambia_fase quando una barra di fase si svuota.
func intermezzo_fase(boss: SiegeBoss, fase: int) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	# I nemici evocati spariscono — resta solo il boss (campo pulito per il colpo di scena).
	for e in _enemies.duplicate():
		if e != null and is_instance_valid(e) and e != boss:
			_morte_poof(e.global_position, e.colore)
			_enemies.erase(e)
			e.queue_free()
	_spawn_queue.clear()
	# Ricompensa di fase (piccola): un attimo di respiro per ripiazzare/potenziare i difensori.
	risorse += 25
	_aggiorna_risorse()
	cinematica_trasformazione(boss, fase)


# Bombardamento del MINI-BOSS caster: telegrafa una zona (su un difensore vicino o davanti al
# villaggio), poi colpisce ad area dopo ~0.7s. Evitabile spargendo le difese e rompendo lo scudo.
func mini_boss_bombarda(origine: Vector2, _col: Color = Color.WHITE) -> void:
	if not _attivo or _concluso:
		return
	var raggio: float = 100.0
	var bersaglio: Vector2 = Vector2(VILLAGGIO_X + randf_range(120.0, 320.0),
		_corsia_y(randi() % N_FILE_SPAWN))
	var lista: Array = difensori_in_area(origine, 1400.0)
	if not lista.is_empty():
		var d0: Node = lista[randi() % lista.size()]
		if d0 != null and is_instance_valid(d0):
			bersaglio = d0.global_position
	var marker: Node = _telegrafo_disco(bersaglio, raggio)
	var dmg: int = 20 + 6 * (era - 1)   # mini-boss caster: colpo che FA male (telegrafato, evitabile)
	var t: Tween = create_tween()
	t.tween_interval(0.7)
	t.tween_callback(func() -> void:
		if is_instance_valid(marker):
			marker.queue_free()
		danno_area_difensori(bersaglio, raggio, dmg)
		fx_esplosione(bersaglio, raggio)
		hitstop(0.05, 0.2))


# Il boss chiama rinforzi (§4): n nemici leggeri dell'era entrano dal lato spawn.
func evoca_rinforzi_boss(n: int) -> void:
	if not _attivo or _concluso or _enemies.size() > 55:
		return
	var lista: Array = ONDATE_NORMALI.get(era, ONDATE_NORMALI[1])[0]["cr"]
	var hp_r: int = int(round(26.0 * (1.0 + 0.18 * float(era - 1))))
	for i in range(n):
		_spawn_enemy({"hp": hp_r, "vel": 84.0, "danno": 8, "bounty": 1,
			"corsia": i % N_FILE_SPAWN, "creatura": str(lista[i % lista.size()])})
	AudioManager.play_sfx("drag_hover")


# --- API usate da difensori/nemici/proiettili (disaccoppiamento) ------------

func bersaglio_per(da: Vector2, raggio: float) -> SiegeEnemy:
	# Nemico più avanzato (x minore = più vicino al villaggio) entro il raggio. Il BOSS ha forte
	# PRIORITÀ (x effettiva -500): altrimenti i suoi add gli fanno da scudo e resta inuccidibile.
	var best: SiegeEnemy = null
	var best_x: float = INF
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo():
			continue
		if da.distance_to(e.global_position) > raggio:
			continue
		var ex: float = e.global_position.x
		if _boss != null and e == _boss:
			ex -= 500.0
		if ex < best_x:
			best_x = ex
			best = e
	return best


func nemico_per_blocco(pos: Vector2, reach: float) -> SiegeEnemy:
	# Nemico davanti al bloccatore (x maggiore) entro la portata e la banda verticale.
	var best: SiegeEnemy = null
	var best_x: float = INF
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo():
			continue
		var ex: float = e.global_position.x
		if ex >= pos.x and ex - pos.x <= reach and absf(e.global_position.y - pos.y) <= BANDA_Y and ex < best_x:
			best_x = ex
			best = e
	return best


func cerca_blocco(pos: Vector2) -> SiegeDefender:
	# Bloccatore vivo più vicino DAVANTI (x minore) entro la banda verticale del chiamante.
	var best: SiegeDefender = null
	var best_x: float = -INF
	for i in range(_blocchi.size() - 1, -1, -1):
		var d: SiegeDefender = _blocchi[i]
		if d == null or not is_instance_valid(d) or not d.vivo():
			_blocchi.remove_at(i)
			continue
		if d.global_position.x < pos.x and absf(d.global_position.y - pos.y) <= BANDA_Y and d.global_position.x > best_x:
			best_x = d.global_position.x
			best = d
	return best


func nemici_in_area(pos: Vector2, raggio: float) -> Array:
	var out: Array = []
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo():
			continue
		if pos.distance_to(e.global_position) <= raggio:
			out.append(e)
	return out


# --- API per il boss (Fase C) -----------------------------------------------

func difensori_in_area(pos: Vector2, raggio: float) -> Array:
	var out: Array = []
	for i in range(_difensori.size() - 1, -1, -1):
		var d: SiegeDefender = _difensori[i]
		if d == null or not is_instance_valid(d):
			_difensori.remove_at(i)
			continue
		if pos.distance_to(d.global_position) <= raggio:
			out.append(d)
	return out


func danno_area_difensori(pos: Vector2, raggio: float, danno: int) -> void:
	for d in difensori_in_area(pos, raggio):
		if is_instance_valid(d):
			# Scudo di pelli (Bloccatore Lv3 vicino): -40% danno ad area subìto.
			var dmg: int = int(round(float(danno) * 0.6)) if _scudo_attivo(d.global_position) else danno
			d.colpisci(dmg)


# C'è un Bloccatore di Lv3+ entro 130px da `pos`? (Scudo di pelli: mitiga il danno ad area.)
func _scudo_attivo(pos: Vector2) -> bool:
	for d in _difensori:
		if is_instance_valid(d) and d.tipo == "bloccatore" and d.livello >= 3 \
				and d.vivo() and pos.distance_to(d.global_position) <= 130.0:
			return true
	return false


# Danno ad area sui NEMICI (ultimate/brace/calore delle unità ascese). Ritorna i colpiti.
func danno_area_nemici(pos: Vector2, raggio: float, danno: int) -> int:
	var n: int = 0
	for e in nemici_in_area(pos, raggio):
		if is_instance_valid(e):
			e.subisci_danno(danno)
			n += 1
	return n


# --- Ultimate delle unità ASCESE (Lv5), auto-cast periodico (Docs/14 §3) -----

func ultimate_tiratore(pos: Vector2, danno: int) -> void:
	# Pioggia di lance: raffica ad area davanti al tiratore.
	var centro: Vector2 = pos + Vector2(230.0, -10.0)
	danno_area_nemici(centro, 150.0, danno)
	fx_anello(centro, 150.0, Color(1.0, 0.92, 0.6))


func ultimate_totem(pos: Vector2, danno: int) -> void:
	# Eruzione: colonna di fuoco ad area.
	var centro: Vector2 = pos + Vector2(190.0, 0.0)
	danno_area_nemici(centro, 145.0, danno)
	fx_esplosione(centro, 145.0)


func ultimate_sciamano(pos: Vector2, raggio: float) -> void:
	# Tempesta di ghiaccio: congela (rallentamento fortissimo) i nemici vicini.
	for e in nemici_in_area(pos, raggio):
		if is_instance_valid(e):
			e.applica_slow(0.08, 2.2)
	fx_anello(pos, raggio, Color(0.6, 0.92, 1.0))


func ultimate_bloccatore(pos: Vector2) -> void:
	# Grido di guerra: stordisce i nemici davanti, in banda.
	for e in _enemies:
		if e == null or not is_instance_valid(e) or not e.vivo():
			continue
		var ex: float = e.global_position.x
		if ex >= pos.x and ex - pos.x <= 280.0 and absf(e.global_position.y - pos.y) <= 95.0:
			e.stordisci(1.4)
	_scuoti()
	fx_anello(pos + Vector2(120.0, 0.0), 180.0, Color(1.0, 0.85, 0.5))


# Brace (Totem Lv3): zona di fuoco a terra che brucia nel tempo (tick di danno per ~2s).
func crea_brace(pos: Vector2, danno: int) -> void:
	fx_brace(pos)
	var t: Tween = create_tween()
	for i in range(4):
		t.tween_callback(func() -> void: danno_area_nemici(pos, 72.0, danno))
		t.tween_interval(0.5)


func stordisci_difensori(durata: float) -> void:
	for i in range(_difensori.size() - 1, -1, -1):
		var d: SiegeDefender = _difensori[i]
		if d == null or not is_instance_valid(d):
			_difensori.remove_at(i)
			continue
		d.stordisci(durata)


func scuoti_forte() -> void:
	var t: Tween = create_tween()
	for i in range(6):
		t.tween_property(self, "offset", Vector2(randf_range(-14, 14), randf_range(-9, 9)), 0.045)
	t.tween_property(self, "offset", Vector2.ZERO, 0.1)


# Hit-stop (Fase F5 juice): micro-freeze per i colpi DECISIVI (rottura tenuta, morte boss,
# impatto ultimate) — dà "peso" all'impatto. Solo sui momenti grossi (no su ogni colpo, per
# non rendere il gioco a scatti). Ripristina il time_scale precedente in modo robusto;
# re-entrant-safe così hit-stop sovrapposti non lo lasciano bloccato lento.
func hitstop(dur: float = 0.09, scala: float = 0.05) -> void:
	if _in_hitstop:
		return
	var prev: float = Engine.time_scale
	if prev <= scala:
		return
	_in_hitstop = true
	Engine.time_scale = scala
	var tmr: SceneTreeTimer = get_tree().create_timer(dur, true, false, true)
	tmr.timeout.connect(func() -> void:
		Engine.time_scale = prev
		_in_hitstop = false)


func segnala_abilita_boss(nome: String) -> void:
	var etich: Dictionary = {
		"pestone": "PESTONE — scansati!",
		"ruggito": "RUGGITO — i difensori vacillano",
		"carica": "CARICA — il boss sfonda!",
		"soffio": "SOFFIO DI FUOCO — sgombra la corsia!",
		"pioggia": "PIOGGIA DI FUOCO — disperdi le unità!",
	}
	_flash_info(etich.get(nome, nome))
	if _vignetta_furia != null and is_instance_valid(_vignetta_furia):
		_pulsa_vignetta_furia()   # le abilità in furia ravvivano la vignetta rossa


func lancia_proiettile(da: Vector2, bersaglio: SiegeEnemy, danno: int, aoe_raggio: float = 0.0,
		pierce: int = 0, brace: bool = false) -> void:
	var p: SiegeProjectile = SiegeProjectile.new()
	p.bersaglio = bersaglio
	p.danno = danno
	p.aoe_raggio = aoe_raggio
	p.pierce = pierce
	p.brace = brace
	p.arena = self
	p.sprite = _fx_tex("proiettile_aoe") if aoe_raggio > 0.0 else _fx_tex("proiettile")
	_world.add_child(p)
	p.global_position = da + Vector2(0.0, -28.0)
	_muzzle_flash(da + Vector2(8.0, -28.0))
	AudioManager.play_sfx("drop_success")


# Lampo di sparo all'origine del proiettile: piccolo bagliore caldo che svanisce.
func _muzzle_flash(pos: Vector2) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = _disc_texture()
	s.centered = true
	s.modulate = Color(1.0, 0.85, 0.5, 0.85)
	s.scale = Vector2(0.22, 0.22)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.tween_property(s, "scale", Vector2(0.5, 0.5), 0.12)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.12)
	t.tween_callback(s.queue_free)


func fx_esplosione(pos: Vector2, raggio: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = _disc_texture()
	s.centered = true
	s.modulate = Color(1.0, 0.6, 0.25, 0.6)
	var base: float = raggio * 2.0 / 64.0
	s.scale = Vector2(base * 0.4, base * 0.4)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.tween_property(s, "scale", Vector2(base, base), 0.25)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.25)
	t.tween_callback(s.queue_free)


# Anello che si espande e svanisce (ultimate delle unità ascese), nel colore dato.
func fx_anello(pos: Vector2, raggio: float, col: Color) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	var s: Sprite2D = Sprite2D.new()
	s.texture = _disc_texture()
	s.centered = true
	s.modulate = Color(col.r, col.g, col.b, 0.55)
	var base: float = raggio * 2.0 / 64.0
	s.scale = Vector2(base * 0.3, base * 0.3)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.tween_property(s, "scale", Vector2(base, base), 0.32)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.32)
	t.tween_callback(s.queue_free)


# Esplosione di scintille/ember (per i momenti grossi: trasformazione del boss).
func _burst_ember(pos: Vector2, col: Color) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = _disc_texture()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 40
	p.lifetime = 0.95
	p.spread = 180.0
	p.gravity = Vector2(0, 140)
	p.initial_velocity_min = 200.0
	p.initial_velocity_max = 560.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.85
	var ramp: Gradient = Gradient.new()
	ramp.colors = PackedColorArray([Color(col.r, col.g, col.b, 1.0), Color(0.45, 0.18, 0.1, 0.0)])
	p.color_ramp = ramp
	_world.add_child(p)
	p.global_position = pos
	var t: Tween = create_tween()
	t.tween_interval(1.5)
	t.tween_callback(p.queue_free)


# VFX da sprite REALE (impatto_terra/fiammata_drago/onda_ruggito/aura_gelo/portale_evoca):
# appare alla larghezza `dim`, si accende e svanisce. Fallback all'esplosione generica se manca.
func fx_vfx(pos: Vector2, dim: float, nome: String, dir_destra: bool = false) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	var tex: Texture2D = _fx_tex(nome)
	if tex == null:
		fx_esplosione(pos, dim * 0.5)
		return
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = true
	var base: float = dim / float(maxi(tex.get_width(), 1))
	s.scale = Vector2((base if dir_destra else -base), base) * 0.8   # i nemici guardano a SINISTRA
	s.modulate = Color(1, 1, 1, 0.0)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.tween_property(s, "modulate:a", 1.0, 0.07)
	t.parallel().tween_property(s, "scale", Vector2((base if dir_destra else -base), base), 0.16)
	t.tween_property(s, "modulate:a", 0.0, 0.34)
	t.tween_callback(s.queue_free)


# Macchia di fuoco a terra (Brace del Totem): resta accesa ~2s e svanisce.
func fx_brace(pos: Vector2) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	var s: Sprite2D = Sprite2D.new()
	s.texture = _disc_texture()
	s.centered = true
	s.modulate = Color(1.0, 0.5, 0.2, 0.0)
	s.scale = Vector2(2.3, 2.3)
	_world.add_child(s)
	s.global_position = pos
	var t: Tween = create_tween()
	t.tween_property(s, "modulate:a", 0.5, 0.25)
	t.tween_interval(1.5)
	t.tween_property(s, "modulate:a", 0.0, 0.4)
	t.tween_callback(s.queue_free)


# --- Schieramento difensori -------------------------------------------------

# Numero di danno fluttuante (usato sul boss): sale e svanisce. crit = colpo durante la
# finestra VULNERABILE → più grande e dorato, così il burst si VEDE.
func fx_numero_danno(pos: Vector2, n: int, crit: bool) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	var lbl: Label = Label.new()
	lbl.text = str(n)
	lbl.add_theme_font_size_override("font_size", 32 if crit else 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36) if crit else Color(1.0, 0.96, 0.9))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.02, 0.95))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 60
	_world.add_child(lbl)
	lbl.position = pos + Vector2(randf_range(-22.0, 22.0), -58.0)
	var t: Tween = create_tween()
	t.set_parallel()
	t.tween_property(lbl, "position:y", lbl.position.y - 48.0, 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(lbl.queue_free)


# Evoca un'unità: compare al CANCELLO del villaggio (con un pop) e poi cammina fino al suo
# posto in formazione, che `_ridisponi` calcola coprendo l'altezza (Docs/14 §1). Restituisce
# l'unità (per i ritocchi degli alleati).
func _piazza(tipo: String, alleato: bool = false) -> SiegeDefender:
	var d: SiegeDefender = _crea_unita(tipo)
	d.corsia = 0
	d.slot = -1
	d.alleato = alleato
	if d.ruolo == "blocco":
		_blocchi.append(d)
		d.distrutto.connect(_on_blocco_distrutto)
	_difensori.append(d)
	_world.add_child(d)
	# Parte dal cancello (lato villaggio), poi `_ridisponi` lo manda al suo posto camminando.
	d.global_position = Vector2(VILLAGGIO_X - 30.0, ROAD_MID + randf_range(-30.0, 30.0))
	_pop_evoca(d)
	_ridisponi("fronte" if d.ruolo == "blocco" else "retro")
	return d


# Scatto d'evocazione: l'unità compare con un pop di scala + un alone caldo al cancello.
func _pop_evoca(d: Node2D) -> void:
	d.scale = Vector2(0.5, 0.5)
	var t: Tween = create_tween()
	t.tween_property(d, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_morte_poof(d.global_position, Color(0.95, 0.86, 0.55))


# Costruisce un'unità con parametri SCALATI dalle stat della run E dal livello del tipo.
func _crea_unita(tipo: String) -> SiegeDefender:
	var def: Dictionary = ROSTER[tipo]
	var skin: Dictionary = _skin[tipo]
	var lv: int = int(_livello[tipo])
	var d: SiegeDefender = SiegeDefender.new()
	d.arena = self
	d.ruolo = def["ruolo"]
	d.tipo = tipo
	d.livello = lv
	d.nome = skin["nome"]
	d.colore = skin["colore"]
	d.sprite = _sprite_difensore(tipo, lv)
	d.costo = int(def["costo"])
	d.cadenza = maxf(0.25, float(def["cadenza"]) * (1.0 - 0.08 * float(lv - 1)))
	d.raggio_tiro = float(def["raggio"]) * (1.0 + 0.10 * float(lv - 1))
	var s: Dictionary = _stat_unita(tipo)
	d.danno = int(s["danno"])
	if tipo == "bloccatore":
		d.hp_max = int(s["hp"])
		d.hp = d.hp_max
	elif tipo == "sciamano":
		d.slow_fattore = float(s["slow"])
		d.slow_durata = 0.7
	elif tipo == "totem":
		d.aoe_raggio = float(s["aoe"])
	return d


# Valori di combattimento di un'unità, scalati dalle stat correnti E dal livello del tipo.
# Unica fonte di verità per `_crea_unita`, `_ristat_difensore` e il tooltip (niente divergenze).
func _stat_unita(tipo: String) -> Dictionary:
	var out: Dictionary = {"danno": 0, "hp": 0, "aoe": 0.0, "slow": 0.0}
	var m: float = _lv_mult(int(_livello[tipo]))
	match tipo:
		"tiratore":
			out["danno"] = int(round((6 + int(GameState.get_stat("militare") / 9.0)) * m))
		"bloccatore":
			out["hp"] = int(round((45 + int(GameState.get_stat("costruzione") * 1.3) + int(GameState.get_stat("militare") * 0.3)) * m))
			out["danno"] = int(round((4 + int(GameState.get_stat("militare") / 14.0)) * m))
		"sciamano":
			# Più livello = rallenta di più (fattore più basso).
			var base_slow: float = clampf(0.62 - float(GameState.get_stat("scienza")) / 420.0, 0.34, 0.62)
			out["slow"] = clampf(base_slow * (1.0 - 0.06 * float(int(_livello[tipo]) - 1)), 0.18, 0.62)
		"totem":
			out["danno"] = int(round((6 + int(float(GameState.get_stat("scienza") + GameState.get_stat("spionaggio")) / 14.0)) * m))
			out["aoe"] = (80.0 + float(GameState.get_stat("scienza")) / 3.0) * (1.0 + 0.12 * float(int(_livello[tipo]) - 1))
	return out


# Tooltip della carta: livello, stat reali del livello attuale, e cosa sblocca il prossimo
# (Lv3 abilità, Lv5 ascensione) + abilità già ottenute. Per i giocatori "strategist".
func _tooltip_unita(tipo: String) -> String:
	var s: Dictionary = _stat_unita(tipo)
	var nome: String = _skin[tipo]["nome"]
	var lv: int = int(_livello[tipo])
	var raggio: int = int(float(ROSTER[tipo]["raggio"]) * (1.0 + 0.10 * float(lv - 1)))
	var cad: float = maxf(0.25, float(ROSTER[tipo]["cadenza"]) * (1.0 - 0.08 * float(lv - 1)))
	var righe: Array[String] = ["%s — Lv %d/%d" % [nome, lv, LV_MAX]]
	match tipo:
		"tiratore":
			righe.append("Danno %d · raggio %d · ogni %.1fs (Militare)" % [int(s["danno"]), raggio, cad])
		"bloccatore":
			righe.append("HP %d · danno mischia %d (Costruzione)" % [int(s["hp"]), int(s["danno"])])
		"sciamano":
			righe.append("Velocità nemici ×%.2f · raggio %d (Scienza)" % [float(s["slow"]), raggio])
		"totem":
			righe.append("Danno %d · raggio AoE %d · ogni %.1fs (Scienza/Spionaggio)" % [int(s["danno"]), int(s["aoe"]), cad])
	# Abilità già sbloccate.
	if lv >= 3:
		righe.append("✓ %s: %s" % [str(ABILITA[tipo]["lv3"]["nome"]), str(ABILITA[tipo]["lv3"]["desc"])])
	if lv >= LV_MAX:
		righe.append("✦ %s + passivo %s" % [str(ABILITA[tipo]["lv5"]["nome"]), str(ABILITA[tipo]["lv5"]["passivo"]["nome"])])
	# Prossimo sblocco.
	if lv < 3:
		righe.append("→ Lv3: %s" % str(ABILITA[tipo]["lv3"]["nome"]))
	elif lv < LV_MAX:
		righe.append("→ Lv5 (ascensione): %s + %s" % [str(ABILITA[tipo]["lv5"]["nome"]), str(ABILITA[tipo]["lv5"]["passivo"]["nome"])])
	return "\n".join(righe)


func _on_blocco_distrutto(_slot: int) -> void:
	AudioManager.play_sfx("stat_down")


# Le civiltà amiche schierano truppe gratuite (tiratori) nel retro; le ostili sono già nei
# rinforzi nemici. Si auto-schierano in formazione come le unità evocate.
func _schiera_alleati() -> void:
	for i in range(_alleati_civ.size()):
		var d: SiegeDefender = _piazza("tiratore", true)
		d.colore = Color(0.55, 0.92, 0.6)
		d.danno = maxi(5, d.danno - 1)
		d.queue_redraw()


# Usato dallo shoot harness/playtest per popolare lo schieramento senza click reali: evoca
# (gratis) un'unità del tipo in formazione. Lo `slot` è ignorato (compat. Fase B).
func schiera_unita_test(_slot: int, tipo: String) -> void:
	_piazza(tipo, false)


# DEBUG: salta DRITTO all'ondata BOSS (per testare il boss fight). Usato da tools/boss_arena.tscn.
func debug_solo_boss() -> void:
	_spawn_queue.clear()
	for e in _enemies.duplicate():
		if is_instance_valid(e):
			e.queue_free()
	_enemies.clear()
	_boss = null
	if _boss_box != null and is_instance_valid(_boss_box):
		_boss_box.queue_free()
		_boss_box = null
	if not _ondate.is_empty():
		_ondate = [_ondate[_ondate.size() - 1]]   # solo l'ultima ondata = il BOSS
	_ondata_idx = -1
	_concluso = false
	_in_pausa = true
	_pausa_fino = _tempo + 1.2
	risorse = 400
	_aggiorna_risorse()
	_flash_info("DEBUG — 1=Colosso  2=Drago  R=ricomincia  ·  piazza i difensori!")


# Compatibilità con la Fase A (shoot harness): piazza un tiratore.
func schiera_difensore_test(slot: int) -> void:
	schiera_unita_test(slot, "tiratore")


# Usato dallo shoot harness: spawn immediato di un nemico di un tipo, riposizionato a `x`
# sulla fila `corsia` (per popolare la mandria nello screenshot senza aspettare le ondate).
func spawn_enemy_test(creatura: String, corsia: int, x: float) -> void:
	if _world == null:
		return
	_spawn_enemy({"hp": 30, "vel": 60.0, "danno": 8, "bounty": 2,
		"corsia": corsia, "creatura": creatura})
	if not _enemies.is_empty():
		var e: SiegeEnemy = _enemies[-1]
		if is_instance_valid(e):
			e.global_position = Vector2(x, _corsia_y(corsia))


# Usato dallo shoot harness: fa entrare subito il boss (salta le ondate).
func spawn_boss_test(abilita_subito: bool = false) -> void:
	var nome_boss: String = "Il Drago" if era >= 2 else "Il Colosso"
	_spawn_boss({"boss": true, "hp": 320, "vel": 34.0, "danno": 45, "corsia": 1, "nome": nome_boss})
	if abilita_subito and _boss != null:
		# Salta l'entrata e forza un'abilità imminente (per lo screenshot del telegrafo).
		_boss._stato = "marcia"
		_boss._bt = 0.0
		_boss._abil_t = 0.3


# --- Esito ------------------------------------------------------------------

# Esito di vittoria graduato dall'HP del villaggio rimasto (Fase F).
func _esito_vittoria() -> String:
	if hp_villaggio >= hp_villaggio_max:
		return "immacolata"
	if hp_villaggio >= int(hp_villaggio_max * 0.4):
		return "trionfo"
	return "fatica"


func _termina(esito: String) -> void:
	if _concluso:
		return
	_concluso = true
	_attivo = false
	_mostra_esito(esito)


func _mostra_esito(esito: String) -> void:
	var vinto: bool = esito != "sopraffatto"
	var info: Dictionary = ESITO_INFO.get(esito, ESITO_INFO["trionfo"])
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(dim)

	var box: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.085, 0.07, 0.96)
	sb.border_color = Color(0.6, 0.44, 0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(26)
	box.add_theme_stylebox_override("panel", sb)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -300.0
	box.offset_right = 300.0
	box.offset_top = -150.0
	box.offset_bottom = 150.0
	dim.add_child(box)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	box.add_child(vb)

	var t1: Label = Label.new()
	t1.text = str(info["titolo"])
	t1.add_theme_font_size_override("font_size", 38)
	t1.add_theme_color_override("font_color", info["colore"])
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)

	var t2: Label = Label.new()
	t2.text = str(info["testo"])
	t2.add_theme_font_size_override("font_size", 17)
	t2.add_theme_color_override("font_color", Color(0.85, 0.8, 0.68))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)

	var continua: Button = Button.new()
	continua.text = "Continua"
	continua.pressed.connect(func() -> void: assedio_concluso.emit(esito))
	vb.add_child(continua)

	if esito == "sopraffatto":
		var riprova: Button = Button.new()
		riprova.text = "Riprova l'Assedio"
		riprova.pressed.connect(func() -> void:
			dim.queue_free()
			_riprova())
		vb.add_child(riprova)

	AudioManager.play_sfx("ledger_unlock" if vinto else "stat_down")

	if vinto:
		# Momento epico: lampo dorato a tutto schermo + titolo che entra con scatto + shake.
		var flash: ColorRect = ColorRect.new()
		flash.color = Color(1.0, 0.86, 0.42, 0.0)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(flash)
		var ft: Tween = create_tween()
		ft.tween_property(flash, "color:a", 0.5, 0.12)
		ft.tween_property(flash, "color:a", 0.0, 0.55)
		ft.tween_callback(flash.queue_free)
		t1.pivot_offset = t1.size * 0.5
		t1.scale = Vector2(0.6, 0.6)
		var pt: Tween = create_tween()
		pt.tween_property(t1, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		AudioManager.play_sfx("quest_complete")
		scuoti_forte()


func _riprova() -> void:
	# Ripristina eventuale zoom della cinematica boss rimasto a metà.
	_world.scale = Vector2.ONE
	_world.position = Vector2.ZERO
	Engine.time_scale = 1.0
	# Pulisci eventuali barre letterbox rimaste da una cinematica interrotta.
	if _lb_top != null and is_instance_valid(_lb_top):
		_lb_top.queue_free()
	if _lb_bot != null and is_instance_valid(_lb_bot):
		_lb_bot.queue_free()
	_lb_top = null
	_lb_bot = null
	for c in _world.get_children():
		c.queue_free()
	_enemies.clear()
	_blocchi.clear()
	_difensori.clear()
	_boss = null
	if _boss_box != null and is_instance_valid(_boss_box):
		_boss_box.queue_free()
		_boss_box = null
	if _vignetta_tween != null and _vignetta_tween.is_valid():
		_vignetta_tween.kill()
	_vignetta_tween = null
	if _vignetta_furia != null and is_instance_valid(_vignetta_furia):
		_vignetta_furia.queue_free()
	_vignetta_furia = null
	_spawn_queue.clear()
	for k in _livello.keys():
		_livello[k] = 1
	configura(era)
	_tempo = 0.0
	_schiera_alleati()
	_prepara_ondate()
	_aggiorna_hp()
	_aggiorna_risorse()
	_aggiorna_diplo()
	_concluso = false
	_attivo = true


# --- HUD refresh / fx -------------------------------------------------------

func _aggiorna_hp() -> void:
	if _hp_label != null:
		_hp_label.text = "Villaggio  %d / %d" % [hp_villaggio, hp_villaggio_max]
	if _hp_fill != null:
		var frac: float = clampf(float(hp_villaggio) / float(maxi(hp_villaggio_max, 1)), 0.0, 1.0)
		_hp_fill.anchor_right = frac
		# Barra di salute a colpo d'occhio (verde sano → ambra → rosso critico).
		if frac > 0.6:
			_hp_fill.color = Color(0.46, 0.70, 0.40)
		elif frac > 0.3:
			_hp_fill.color = Color(0.85, 0.70, 0.34)
		else:
			_hp_fill.color = Color(0.82, 0.30, 0.26)


func _aggiorna_risorse() -> void:
	if _risorse_label != null:
		_risorse_label.text = "Monete: %d" % risorse
	_aggiorna_cards()


func _aggiorna_ondata_label() -> void:
	if _ondata_label != null:
		var n: int = clampi(_ondata_idx + 1, 0, _ondate.size())
		_ondata_label.text = "Ondata %d / %d  ·  in campo: %d" % [n, _ondate.size(), _enemies.size()]


# Banner d'ondata (telegrafia): cartiglio bronzo (§8i) se presente, altrimenti label nuda.
func _mostra_banner(testo: String) -> void:
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = 196.0
	holder.offset_bottom = 320.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cartiglio dedicato dell'Assedio (§P7 7k) se presente, altrimenti il cartouche UI-kit.
	var cart: Texture2D = _siege_ui_tex("wave_banner")
	if cart == null:
		cart = UiStyle.ui_texture("cartouche")
	if cart != null:
		var np: NinePatchRect = NinePatchRect.new()
		np.texture = cart
		np.patch_margin_left = 80
		np.patch_margin_right = 80
		np.patch_margin_top = 30
		np.patch_margin_bottom = 30
		np.anchor_left = 0.5
		np.anchor_right = 0.5
		np.offset_left = -380.0
		np.offset_right = 380.0
		np.offset_top = 0.0
		np.offset_bottom = 124.0
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(np)
	var lbl: Label = Label.new()
	lbl.text = testo
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.97, 0.86, 0.52))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(lbl)
	_ui.add_child(holder)
	holder.modulate.a = 0.0
	# Punch: il banner "atterra" con uno scatto (scale-pop + colpetto) invece di comparire.
	var vw: float = get_viewport().get_visible_rect().size.x
	holder.pivot_offset = Vector2(vw * 0.5, 62.0)
	holder.scale = Vector2(0.78, 0.78)
	var t: Tween = create_tween()
	t.tween_property(holder, "modulate:a", 1.0, 0.18)
	t.parallel().tween_property(holder, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(_scuoti)   # colpetto al picco: il banner ha peso
	t.tween_interval(1.5)
	t.tween_property(holder, "modulate:a", 0.0, 0.5)
	t.tween_callback(holder.queue_free)


func _aggiorna_diplo() -> void:
	if _diplo_label == null:
		return
	var parti: Array[String] = []
	if not _alleati_civ.is_empty():
		parti.append("▲ Alleati: %s" % ", ".join(_alleati_civ))
	if not _ostili_civ.is_empty():
		parti.append("▼ Ostili: %s" % ", ".join(_ostili_civ))
	_diplo_label.text = "   ·   ".join(parti)
	_diplo_label.visible = not parti.is_empty()


func _flash_info(msg: String) -> void:
	if _info_label == null:
		return
	_info_label.text = msg
	_info_label.modulate = Color(1.0, 0.6, 0.5)
	var t: Tween = create_tween()
	t.tween_property(_info_label, "modulate", Color.WHITE, 0.8)


func _scuoti() -> void:
	var t: Tween = create_tween()
	for i in range(4):
		t.tween_property(self, "offset", Vector2(randf_range(-7, 7), randf_range(-4, 4)), 0.05)
	t.tween_property(self, "offset", Vector2.ZERO, 0.08)


# Cornice bronzo del UI kit (§8h) sopra una barra HP: la traccia/riempimento restano
# dietro, il frame ornato (centro trasparente) la incornicia. Fallback-safe: niente frame
# se l'asset manca (resta la barra a colori). Vedi Docs/13-redesign-estetico.md.
func _decora_barra(track: Control) -> void:
	var frame: Texture2D = UiStyle.ui_texture("bar_frame")
	if frame == null:
		return
	var np: NinePatchRect = NinePatchRect.new()
	np.texture = frame
	np.set_anchors_preset(Control.PRESET_FULL_RECT)
	np.patch_margin_left = 26
	np.patch_margin_right = 26
	np.patch_margin_top = 5
	np.patch_margin_bottom = 5
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(np)


# Sbuffo di morte di un nemico: scintille brevi + alone, juice senza asset.
func _morte_poof(pos: Vector2, col: Color) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = _disc_texture()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 12
	p.lifetime = 0.5
	p.direction = Vector2(-0.4, -1.0)
	p.spread = 180.0
	p.gravity = Vector2(0, 240)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 0.18
	p.scale_amount_max = 0.4
	var ramp: Gradient = Gradient.new()
	ramp.colors = PackedColorArray([
		Color(col.r, col.g, col.b, 0.95), Color(0.4, 0.25, 0.2, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = ramp
	_world.add_child(p)
	p.global_position = pos
	var t: Tween = create_tween()
	t.tween_interval(0.9)
	t.tween_callback(p.queue_free)


# Lampo rosso di vignetta quando il villaggio incassa: feedback di danno chiaro.
func _flash_danno() -> void:
	var fl: ColorRect = ColorRect.new()
	fl.color = Color(0.7, 0.1, 0.08, 0.0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fl)
	var t: Tween = create_tween()
	t.tween_property(fl, "color:a", 0.30, 0.06)
	t.tween_property(fl, "color:a", 0.0, 0.4)
	t.tween_callback(fl.queue_free)


# Vignetta rossa della FURIA del boss (A2): i bordi si accendono di rosso, restano tenui
# finché il boss è infuriato e pulsano all'ingresso e a ogni sua abilità. Riusa lo shader
# vignette già in repo (UiStyle.crea_vignette), fallback-safe se lo shader manca.
func _vignetta_furia_attiva() -> void:
	if _vignetta_furia == null or not is_instance_valid(_vignetta_furia):
		_vignetta_furia = UiStyle.crea_vignette(0.0, Color(0.85, 0.12, 0.10, 1.0))
		_ui.add_child(_vignetta_furia)
	_pulsa_vignetta_furia()


func _set_vig_intensity(v: float) -> void:
	if _vignetta_furia == null or not is_instance_valid(_vignetta_furia):
		return
	var mat: Material = _vignetta_furia.material
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("intensity", v)
	else:
		_vignetta_furia.color.a = v   # fallback senza shader: alpha del rettangolo


func _pulsa_vignetta_furia() -> void:
	if _vignetta_furia == null or not is_instance_valid(_vignetta_furia):
		return
	if _vignetta_tween != null and _vignetta_tween.is_valid():
		_vignetta_tween.kill()
	_vignetta_tween = create_tween()
	# scatto acceso → si calma a un rosso di base che resta finché il boss è in furia.
	_vignetta_tween.tween_method(_set_vig_intensity, 0.30, 0.62, 0.10)
	_vignetta_tween.tween_method(_set_vig_intensity, 0.62, 0.26, 0.45)


func _dissolvi_vignetta_furia() -> void:
	if _vignetta_tween != null and _vignetta_tween.is_valid():
		_vignetta_tween.kill()
		_vignetta_tween = null
	if _vignetta_furia == null or not is_instance_valid(_vignetta_furia):
		_vignetta_furia = null
		return
	var vf: ColorRect = _vignetta_furia   # resta referenziato da _vignetta_furia durante il fade
	_vignetta_tween = create_tween()
	_vignetta_tween.tween_method(_set_vig_intensity, 0.26, 0.0, 0.5)
	_vignetta_tween.tween_callback(func() -> void:
		if is_instance_valid(vf):
			vf.queue_free()
		_vignetta_furia = null)


func _disc_texture() -> GradientTexture2D:
	var g: Gradient = Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex
