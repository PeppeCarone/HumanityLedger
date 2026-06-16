extends Node2D

const DROP_ZONE_SCENE: PackedScene = preload("res://scenes/ui/drop_zone.tscn")
const DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/ui/draggable_item.tscn")
const LEDGER_SCENE: PackedScene = preload("res://scenes/ledger_screen.tscn")
const ENDING_SCENE: PackedScene = preload("res://scenes/ending_screen.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const WORLD_MAP_SCENE: PackedScene = preload("res://scenes/world_map.tscn")
const CHARACTERS_DIR: String = "res://data/characters/"
const FINALI_DIR: String = "res://data/finali/"
const QUEST_SEQUENZE: Dictionary = {
	1: [
		"q_caverna_tutorial",
		"q_accampamento",
		"q_confronto",
		"q_idolo_del_fuoco",
	],
	2: [
		"q_corte_si_forma",
		"q_pressione_imperi",
		"q_scelta_finale",
	],
}
const CIV_LABELS: Dictionary = {
	"popolo_nebbie": "Popolo delle Nebbie",
	"clan_bisonte": "Clan del Bisonte",
	"impero_sole": "Impero del Sole",
	"lega_coste": "Lega delle Coste",
}
const COLOR_BG_ERA1: Color = Color(0.06, 0.05, 0.08, 0.55)
const COLOR_BG_ERA2: Color = Color(0.09, 0.07, 0.13, 0.5)
const COLOR_BG_MYSTERY: Color = Color(0.18, 0.05, 0.06, 0.6)
const FEEDBACK_PAUSE_SEC: float = 2.5
const STAT_TWEEN_DURATION: float = 0.55
const NARRATIVE_FADE_DURATION: float = 0.4

const COLOR_PROPOSER_NORMALE: Color = Color.WHITE
const COLOR_PROPOSER_CATASTROFE: Color = Color(0.6, 0.8, 1.0)
const COLOR_PROPOSER_SVOLTA: Color = Color(1.0, 0.85, 0.5)
const COLOR_PROPOSER_MISTERO: Color = Color(0.78, 0.6, 1.0)

# Indicatori di effetto-duraturo (lezione Lapse): tinta per categoria.
const COLOR_EFF_ARTEFATTO: Color = Color(0.95, 0.78, 0.4)
const COLOR_EFF_MYSTERY: Color = Color(0.78, 0.6, 1.0)
const COLOR_EFF_ALLEATO: Color = Color(0.6, 0.95, 0.6)
const COLOR_EFF_OSTILE: Color = Color(0.95, 0.55, 0.5)
# Soglia oltre la quale un rapporto vale come patto/ostilita' "attiva".
const SOGLIA_RAPPORTO: int = 2

# colori distinti per accoppiare ogni opzione al consigliere bersaglio (card <-> zona)
const ACCENT_PALETTE: Array[Color] = [
	Color(0.95, 0.78, 0.4),
	Color(0.5, 0.8, 0.95),
	Color(0.72, 0.92, 0.6),
	Color(0.95, 0.62, 0.56),
]

const PREFISSO_TIPO: Dictionary = {
	"catastrofe": "CATASTROFE — ",
	"svolta": "SVOLTA — ",
	"incontro": "INCONTRO — ",
	"mistero": "MISTERO — ",
}

# Richiami narrativi cross-era: una decisione Era 2 cita la scelta presa
# nella decisione Era 1 corrispondente. Chiave = id decisione Era 2; valore =
# lista di {decisione, scelta (target_consigliere_id), testo}. Solo il primo
# match viene mostrato. Lezione Lapse: il mondo ricorda cosa hai scelto.
const RICHIAMI: Dictionary = {
	"d_corte_04_impero": [
		{"decisione": "d_con_01_bisonte", "scelta": "era1_orm",
			"testo": "Generazioni fa lo spirito accolse un inviato disarmato offrendogli il sale, non le lance. Quella scelta è diventata la nostra parola: al tavolo si parla prima di mostrare il ferro."},
		{"decisione": "d_con_01_bisonte", "scelta": "era1_brann",
			"testo": "Generazioni fa lo spirito accolse un inviato schierandogli davanti gli uomini in armi. L'Impero conosce questa fama: noi arriviamo al tavolo già pronti alla guerra."},
		{"decisione": "d_con_01_bisonte", "scelta": "era1_kael",
			"testo": "Generazioni fa lo spirito annuì a un inviato e poi lo seguì nell'ombra. Da allora ogni nostro patto ha una seconda faccia, e i potenti lo sanno."},
	],
	"d_corte_05_lega": [
		{"decisione": "d_con_03_spie", "scelta": "era1_kael",
			"testo": "Quando il Bisonte si mosse lungo il fiume, lo spirito mandò l'ombra a contarne le lance. La Lega lo sa: i nostri occhi arrivano sempre prima delle nostre vele."},
		{"decisione": "d_con_03_spie", "scelta": "era1_brann",
			"testo": "Quando il Bisonte si mosse lungo il fiume, lo spirito restò alla luce, gli uomini in vista. La Lega ci tratta da gente che non nasconde le mani."},
		{"decisione": "d_con_03_spie", "scelta": "era1_orm",
			"testo": "Quando il Bisonte si mosse lungo il fiume, lo spirito mandò parole prima delle ombre. La Lega negozia sapendo che noi parliamo, non spiamo."},
	],
	"d_corte_18_ribellione": [
		{"decisione": "d_con_06_ferito", "scelta": "era1_orm",
			"testo": "Molto tempo fa lo spirito fasciò la gamba di un nemico ferito e lo rimandò ai suoi. Quel gesto è ancora un racconto nelle fornaci: forse stanotte qualcuno là fuori se ne ricorda."},
		{"decisione": "d_con_06_ferito", "scelta": "era1_kael",
			"testo": "Molto tempo fa lo spirito tenne un nemico ferito finché non parlò. La gente delle fornaci sa come trattiamo chi cade nelle nostre mani."},
		{"decisione": "d_con_06_ferito", "scelta": "era1_vesha",
			"testo": "Molto tempo fa lo spirito vendette a peso di pelli la vita di un ferito. La folla là fuori conosce il prezzo che diamo a una vita: il loro."},
	],
}

const STAT_LABELS: Dictionary = {
	"militare": "Militare",
	"tesoro": "Tesoro",
	"diplomazia": "Diplomazia",
	"scienza": "Scienza",
	"legge": "Legge",
	"spionaggio": "Spionaggio",
	"popolo": "Popolo",
	"costruzione": "Costruzione",
}

# --- Villaggio builder (D046): ogni tipo-edificio sviluppa una stat tematica.
# Costruire/migliorare costa RISORSE (la valuta del villaggio, prodotta a ogni
# decisione dagli edifici) ed è gated dalla Costruzione (dominio del Costruttore).
const EDIFICIO_NOME_ERA: Dictionary = {
	1: {0: "Tenda", 1: "Capanna", 2: "Totem", 3: "Focolare", 4: "Essiccatoio", 5: "Palizzata"},
	2: {0: "Tempio", 1: "Mercato", 2: "Torre", 3: "Fonderia", 4: "Mura", 5: "Archivio"},
}
const EDIFICIO_STAT_ERA: Dictionary = {
	1: {0: "popolo", 1: "popolo", 2: "scienza", 3: "legge", 4: "costruzione", 5: "militare"},
	2: {0: "legge", 1: "diplomazia", 2: "spionaggio", 3: "costruzione", 4: "militare", 5: "scienza"},
}
# Edifici "economici": producono RISORSE doppie a ogni turno (essiccatoio / mercato).
const EDIFICIO_ECONOMICO: Dictionary = {
	1: {4: true},
	2: {1: true},
}
# Per raggiungere il livello-chiave: costo Risorse, Costruzione minima, bonus alla stat.
const UPGRADE_COSTO: Dictionary = {2: 14, 3: 24}
const UPGRADE_GATE_COSTR: Dictionary = {2: 30, 3: 55}
const UPGRADE_BONUS: Dictionary = {2: 6, 3: 9}
# Costruire un nuovo edificio sul lotto vuoto: piu' economico dell'upgrade.
const BUILD_COSTO: int = 10
const BUILD_GATE_COSTR: int = 20
const BUILD_BONUS: int = 3
# Produzione base di Risorse per turno (anche con poche strutture si accumula).
const PRODUZIONE_BASE: int = 2

const STAT_ICON_DIR: String = "res://Assets/art/stats/"
# Vista villaggio: terreno-tabellone per era (stile board di strategia, D046).
# Finche' il terreno non esiste si usa come fallback la scena dipinta.
const TERRENO_ERA: String = "res://Assets/art/terreni/era%d.jpg"
# Vista decisione: scene dipinte d'atmosfera dietro il consigliere.
const BG_CAVERNA: String = "res://Assets/art/backgrounds/era1_caverna.jpg"
const BG_ACCAMPAMENTO: String = "res://Assets/art/backgrounds/era1_accampamento.jpg"
const BG_ERA2: String = "res://Assets/art/backgrounds/era2_citta.png"
const BG_ERA2_NOTTE: String = "res://Assets/art/backgrounds/era2_citta_notte.jpg"

@onready var scene_bg: TextureRect = $UI/SceneBg
@onready var hud_container: VBoxContainer = $UI/HUDPanel/VBoxContainer
@onready var consiglieri_row: HBoxContainer = $UI/ConsiglieriRow
@onready var decision_panel_row: HBoxContainer = $UI/DecisionPanel/HBoxContainer
@onready var narrative_label: Label = $UI/NarrativeLabel
@onready var help_label: Label = $UI/HelpLabel
@onready var proposer_portrait: TextureRect = $UI/ConsigliereProposer/HBox/PortraitProposer
@onready var proposer_name_label: Label = $UI/ConsigliereProposer/HBox/VBox/ProposerName
@onready var proposer_text_label: Label = $UI/ConsigliereProposer/HBox/VBox/ProposerText
@onready var event_image: TextureRect = $UI/ConsigliereProposer/HBox/EventImage
@onready var village: VillageView = $UI/VillageView
@onready var call_button: Button = $UI/CallButton
@onready var decision_dim: ColorRect = $UI/DecisionDim
@onready var decision_bg: TextureRect = $UI/DecisionBg
@onready var arriving_portrait: TextureRect = $UI/ArrivingPortrait

var quest_log_label: Label = null
var popolazione_label: Label = null
var risorse_label: Label = null
var produzione_label: Label = null
var stat_value_labels: Dictionary = {}
var rapporti_label: Label = null
var rapporti_box: VBoxContainer = null
var effetti_label: Label = null
var effetti_box: HFlowContainer = null
var richiamo_label: Label = null
var _richiamo_pendente: String = ""
var current_quest: Quest = null
var current_step: int = 0
var personaggi_db: Dictionary = {}
var _decision_accents: Dictionary = {}
var processing_drop: bool = false
var ledger_screen_instance: CanvasLayer = null
var ending_instance: CanvasLayer = null
var pause_instance: CanvasLayer = null
var era_card: CanvasLayer = null
var stat_tweens: Dictionary = {}
var stat_icon_nodes: Dictionary = {}
var narrative_tween: Tween = null
var in_attesa_quest: bool = false
var in_transizione_era: bool = false
var atmosfera: CPUParticles2D = null
var edificio_panel: CanvasLayer = null


func _ready() -> void:
	help_label.text = "Trascina un'azione sul consigliere che la sostiene."
	help_label.add_theme_font_size_override("font_size", 20)
	help_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	help_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	help_label.add_theme_constant_override("outline_size", 4)
	var titolo_font: Font = _font_titoli()
	if titolo_font != null:
		proposer_name_label.add_theme_font_override("font", titolo_font)
	# Gerarchia tipografica del pannello decisione: nome oro, corpo panna arioso.
	proposer_name_label.add_theme_color_override("font_color", Color(0.91, 0.78, 0.48))
	# Testo decisione più grande e caldo (off-white) per leggibilità: è la schermata
	# più vista del gioco (audit UI #4).
	proposer_text_label.add_theme_font_size_override("font_size", 23)
	proposer_text_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.75))
	proposer_text_label.add_theme_constant_override("line_spacing", 8)
	_applica_cornici()
	_crea_vignette()
	_crea_richiamo_label()
	_setup_hud()
	_setup_resource_bar()
	_load_personaggi()
	GameState.stat_changed.connect(_on_stat_changed)
	GameState.popolazione_changed.connect(_on_popolazione_changed)
	GameState.risorse_changed.connect(_on_risorse_changed)
	GameState.mystery_attivata.connect(_on_mystery_attivata)
	GameState.rapporto_changed.connect(_on_rapporto_changed)
	if village != null:
		village.edificio_cliccato.connect(_on_edificio_cliccato)
		village.plot_cliccato.connect(_on_plot_cliccato)
	call_button.pressed.connect(_apri_decisione)
	_stile_call_button()
	_set_decision_visible(false)
	call_button.visible = false
	_start_era1()


# --- Due view: villaggio (default) <-> decisione (overlay) -------------------

func _stile_call_button() -> void:
	var titolo_font: Font = _font_titoli()
	if titolo_font != null:
		call_button.add_theme_font_override("font", titolo_font)
	call_button.add_theme_color_override("font_color", Color(0.97, 0.9, 0.7))
	call_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	call_button.add_theme_constant_override("outline_size", 5)
	for stato in ["normal", "hover", "pressed", "focus"]:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.16, 0.11, 0.07, 0.94) if stato == "hover" else Color(0.12, 0.085, 0.06, 0.92)
		sb.border_color = Color(0.78, 0.55, 0.28)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(10)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 8
		sb.set_content_margin_all(14)
		call_button.add_theme_stylebox_override(stato, sb)


# Nodi che compongono la view-decisione: si mostrano/nascondono come gruppo.
func _decision_nodes() -> Array:
	return [
		$UI/ConsigliereProposer, $UI/ConsiglieriRow,
		$UI/DecisionPanel, help_label, decision_dim, decision_bg,
		richiamo_label,
	]


func _set_decision_visible(mostra: bool) -> void:
	for n in _decision_nodes():
		if n != null:
			n.visible = mostra
	# Il richiamo appare solo se c'e' una memoria da citare per questa decisione.
	if richiamo_label != null:
		richiamo_label.visible = mostra and _richiamo_pendente != ""


func _chiudi_decisione_morbida() -> void:
	# Fade-out della vista decisione: si "atterra" sul villaggio, niente taglio netto.
	var t: Tween = create_tween()
	t.set_parallel()
	for n in _decision_nodes():
		if n != null:
			t.tween_property(n, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(func() -> void:
		_set_decision_visible(false)
		for n in _decision_nodes():
			if n != null:
				n.modulate.a = 1.0)


func _consigliere_in_arrivo(nome: String, ritratto: Texture2D = null) -> void:
	# Un consigliere "arriva": la figura sale dal bordo inferiore (a filo schermo,
	# stile visual novel) e il pulsante-dialogo accanto lampeggia.
	if ritratto != null:
		arriving_portrait.texture = ritratto
		arriving_portrait.visible = true
		var home: Vector2 = Vector2(390.0, 600.0)
		arriving_portrait.position = home + Vector2(0.0, 110.0)
		arriving_portrait.modulate.a = 0.0
		var st: Tween = create_tween()
		st.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		st.tween_property(arriving_portrait, "position:y", home.y, 0.6)
		st.parallel().tween_property(arriving_portrait, "modulate:a", 1.0, 0.5)
	else:
		arriving_portrait.visible = false
	call_button.text = "%s attende il tuo parere\n[ Decidi ]" % nome
	call_button.visible = true
	call_button.modulate.a = 1.0
	var t: Tween = create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(call_button, "modulate:a", 0.45, 0.7)
	t.tween_property(call_button, "modulate:a", 1.0, 0.7)
	call_button.set_meta("blink", t)


func _apri_decisione() -> void:
	if call_button.has_meta("blink"):
		var t: Tween = call_button.get_meta("blink")
		if t != null and t.is_valid():
			t.kill()
	call_button.visible = false
	arriving_portrait.visible = false
	AudioManager.play_sfx("quest_complete")
	_set_decision_visible(true)
	decision_dim.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(decision_dim, "modulate:a", 1.0, 0.35)


# Label dedicata per i richiami narrativi cross-era: una "memoria dello spirito"
# che galleggia sopra il consigliere, nella banda altrimenti vuota durante la
# decisione. Niente resize del pannello: nessun rischio di invadere le scelte.
func _crea_richiamo_label() -> void:
	richiamo_label = Label.new()
	richiamo_label.name = "RichiamoLabel"
	richiamo_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	richiamo_label.offset_left = 470.0
	richiamo_label.offset_top = 120.0
	richiamo_label.offset_right = 1790.0
	richiamo_label.offset_bottom = 220.0
	richiamo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	richiamo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	richiamo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	richiamo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	richiamo_label.add_theme_font_size_override("font_size", 18)
	richiamo_label.add_theme_color_override("font_color", Color(0.74, 0.64, 0.46))
	richiamo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	richiamo_label.add_theme_constant_override("outline_size", 4)
	richiamo_label.visible = false
	$UI.add_child(richiamo_label)


func _crea_vignette() -> void:
	# Vignettatura cinematografica: angoli scuriti, centro pulito. Sta sopra tutta
	# la UI di scena (i CanvasLayer di pausa/ledger restano comunque sopra).
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.36)])
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.25)
	tex.width = 512
	tex.height = 512
	var tr: TextureRect = TextureRect.new()
	tr.name = "Vignette"
	tr.texture = tex
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	$UI.add_child(tr)


# Pulviscolo d'atmosfera per era: in Era 1 motes caldi che scendono lenti nella
# luce del tramonto, in Era 2 braci che salgono dalla citta'. Sta sopra il
# villaggio ma sotto i pannelli e l'overlay decisione (resta nella vista villaggio).
func _aggiorna_atmosfera() -> void:
	var vp: Vector2 = Vector2(1920, 1080)
	if atmosfera == null:
		atmosfera = CPUParticles2D.new()
		atmosfera.name = "Atmosfera"
		atmosfera.texture = _soft_dot_texture()
		atmosfera.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		atmosfera.local_coords = false
		$UI.add_child(atmosfera)
		# Sopra il villaggio (idx 2), sotto DecisionBg/HUD: indice 3.
		$UI.move_child(atmosfera, 3)
	var era2: bool = GameState.era_corrente >= 2
	atmosfera.amount = 22 if era2 else 30
	atmosfera.lifetime = 7.0 if era2 else 9.5
	atmosfera.preprocess = atmosfera.lifetime
	atmosfera.spread = 18.0
	atmosfera.scale_amount_min = 0.5 if era2 else 0.35
	atmosfera.scale_amount_max = 1.4 if era2 else 1.0
	atmosfera.emission_rect_extents = Vector2(vp.x * 0.5, 40.0)
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	if era2:
		# Braci ascendenti: partono dal basso e salgono, ambra-arancio.
		atmosfera.position = Vector2(vp.x * 0.5, vp.y * 0.98)
		atmosfera.direction = Vector2(0, -1)
		atmosfera.gravity = Vector2(3, -16)
		atmosfera.initial_velocity_min = 10.0
		atmosfera.initial_velocity_max = 26.0
		ramp.colors = PackedColorArray([
			Color(1.0, 0.6, 0.3, 0.0), Color(1.0, 0.66, 0.32, 0.55),
			Color(1.0, 0.6, 0.3, 0.0)])
	else:
		# Pulviscolo caldo che scende lento dall'alto.
		atmosfera.position = Vector2(vp.x * 0.5, vp.y * 0.04)
		atmosfera.direction = Vector2(0.2, 1)
		atmosfera.gravity = Vector2(5, 10)
		atmosfera.initial_velocity_min = 4.0
		atmosfera.initial_velocity_max = 12.0
		ramp.colors = PackedColorArray([
			Color(1.0, 0.95, 0.82, 0.0), Color(1.0, 0.94, 0.8, 0.42),
			Color(1.0, 0.95, 0.82, 0.0)])
	atmosfera.color_ramp = ramp
	atmosfera.restart()


func _soft_dot_texture() -> GradientTexture2D:
	var g: Gradient = Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 24
	tex.height = 24
	return tex


func _font_titoli() -> Font:
	var path: String = "res://Assets/fonts/Cinzel.ttf"
	if not ResourceLoader.exists(path):
		return null
	var base: FontFile = load(path)
	var fv: FontVariation = FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": 600}
	return fv


func _applica_cornici() -> void:
	for node_path in ["UI/HUDPanel", "UI/ConsigliereProposer", "UI/DecisionPanel"]:
		var panel: Control = get_node_or_null(node_path)
		if panel == null:
			continue
		panel.add_theme_stylebox_override("panel", _stile_pannello())


func _stile_pannello() -> StyleBoxFlat:
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


func _setup_hud() -> void:
	stat_value_labels.clear()
	stat_icon_nodes.clear()
	for stat_name in GameState.STAT_NAMES:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = STAT_ICON_DIR + stat_name + ".png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		row.add_child(icon)
		stat_icon_nodes[stat_name] = icon
		# Nome a sinistra (tenue), valore a destra (bold chiaro): gerarchia da
		# pannello di comando, non lista di debug.
		var nome_lbl: Label = Label.new()
		nome_lbl.text = STAT_LABELS[stat_name]
		nome_lbl.add_theme_font_size_override("font_size", 16)
		nome_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
		nome_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(nome_lbl)
		var label: Label = Label.new()
		label.name = "Stat_" + stat_name
		label.text = str(GameState.get_stat(stat_name))
		label.add_theme_font_size_override("font_size", 19)
		label.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		hud_container.add_child(row)
		stat_value_labels[stat_name] = label
	var spacer_a: Control = Control.new()
	spacer_a.custom_minimum_size = Vector2(0, 8)
	hud_container.add_child(spacer_a)
	var sep: ColorRect = ColorRect.new()
	sep.color = Color(0.5, 0.38, 0.22, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	hud_container.add_child(sep)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	hud_container.add_child(spacer)
	# Effetti duraturi: badge persistenti che dicono cosa ti protegge/minaccia ora.
	effetti_label = Label.new()
	effetti_label.name = "EffettiLabel"
	effetti_label.add_theme_font_size_override("font_size", 14)
	effetti_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.38))
	effetti_label.visible = false
	hud_container.add_child(effetti_label)
	effetti_box = HFlowContainer.new()
	effetti_box.name = "EffettiBox"
	effetti_box.add_theme_constant_override("h_separation", 6)
	effetti_box.add_theme_constant_override("v_separation", 4)
	hud_container.add_child(effetti_box)
	var spacer_eff: Control = Control.new()
	spacer_eff.custom_minimum_size = Vector2(0, 10)
	hud_container.add_child(spacer_eff)
	popolazione_label = Label.new()
	popolazione_label.name = "Popolazione"
	popolazione_label.text = "Popolazione: %d" % GameState.popolazione
	popolazione_label.add_theme_font_size_override("font_size", 20)
	hud_container.add_child(popolazione_label)
	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	hud_container.add_child(spacer2)
	quest_log_label = Label.new()
	quest_log_label.name = "QuestLog"
	quest_log_label.add_theme_font_size_override("font_size", 18)
	quest_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_container.add_child(quest_log_label)
	var spacer3: Control = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 16)
	hud_container.add_child(spacer3)
	rapporti_label = Label.new()
	rapporti_label.name = "Rapporti"
	rapporti_label.add_theme_font_size_override("font_size", 16)
	rapporti_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_container.add_child(rapporti_label)
	rapporti_box = VBoxContainer.new()
	rapporti_box.name = "RapportiBox"
	rapporti_box.add_theme_constant_override("separation", 4)
	hud_container.add_child(rapporti_box)
	var spacer4: Control = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 14)
	hud_container.add_child(spacer4)
	var tasti: Label = Label.new()
	tasti.name = "Tasti"
	tasti.text = "Clicca un edificio per migliorarlo\nL  Ledger      ESC  Pausa"
	tasti.add_theme_font_size_override("font_size", 14)
	tasti.modulate = Color(1, 1, 1, 0.45)
	hud_container.add_child(tasti)
	_refresh_rapporti()
	_refresh_effetti_duraturi()


func _load_personaggi() -> void:
	personaggi_db.clear()
	var dir: DirAccess = DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		push_error("Cartella personaggi non trovata: " + CHARACTERS_DIR)
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var res: Resource = load(CHARACTERS_DIR + fname)
			if res != null and res.get("id") != null and res.id != "":
				personaggi_db[res.id] = res
		fname = dir.get_next()
	dir.list_dir_end()


func _start_era1() -> void:
	QuestManager.quest_attive.clear()
	QuestManager.quest_chiave_corrente = null
	_aggiorna_sfondo_era()
	_avvia_prossima_quest()


# Scena dipinta d'atmosfera per la vista decisione, in base a era e quest.
func _scena_corrente() -> String:
	if GameState.era_corrente >= 2:
		# Atto finale: la citta' di notte, vigilia della scelta.
		if current_quest != null and current_quest.id == "q_scelta_finale" \
				and ResourceLoader.exists(BG_ERA2_NOTTE):
			return BG_ERA2_NOTTE
		return BG_ERA2
	# Era 1: caverna solo durante il tutorial, poi il popolo esce all'aperto.
	if current_quest != null and current_quest.id != "q_caverna_tutorial":
		return BG_ACCAMPAMENTO
	return BG_CAVERNA


# Sfondo della vista villaggio: il terreno-tabellone (fallback: scena dipinta).
func _terreno_corrente() -> String:
	var path: String = TERRENO_ERA % GameState.era_corrente
	return path if ResourceLoader.exists(path) else _scena_corrente()


func _aggiorna_sfondo_era() -> void:
	if scene_bg == null:
		return
	var path: String = _terreno_corrente()
	if ResourceLoader.exists(path):
		scene_bg.texture = load(path)
		scene_bg.set_meta("bg_path", path)
	_aggiorna_scena_decisione()
	_aggiorna_atmosfera()
	AudioManager.play_music_id("era2" if GameState.era_corrente >= 2 else "era1")
	if village != null:
		var n: int = int(GameState.flag_narrativi.get("villaggio_n", 1))
		village.sincronizza(GameState.era_corrente, n)
		village.aggiorna_prosperita(GameState.popolo, GameState.tesoro)
		_refresh_potenziabili()


func _aggiorna_scena_decisione() -> void:
	if decision_bg == null:
		return
	var path: String = _scena_corrente()
	if ResourceLoader.exists(path):
		decision_bg.texture = load(path)


# Cambio sfondo morbido quando la quest sposta la scena (es. caverna -> accampamento).
func _aggiorna_sfondo_quest() -> void:
	_aggiorna_scena_decisione()
	if scene_bg == null:
		return
	var path: String = _terreno_corrente()
	if str(scene_bg.get_meta("bg_path", "")) == path or not ResourceLoader.exists(path):
		return
	scene_bg.set_meta("bg_path", path)
	var t: Tween = create_tween()
	t.tween_property(scene_bg, "modulate:a", 0.15, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void: scene_bg.texture = load(path))
	t.tween_property(scene_bg, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _avvia_prossima_quest() -> void:
	in_attesa_quest = false
	var q: Quest = _prossima_quest_disponibile()
	if q == null:
		if GameState.era_corrente == 1 and GameState.has_flag("era1_completata"):
			_show_transizione_a_era2()
		elif GameState.era_corrente == 2 and GameState.has_flag("era2_completata"):
			_show_ending()
		else:
			_show_attesa_quest()
		return
	current_quest = q
	QuestManager.avvia_quest(q)
	current_step = 0
	_aggiorna_sfondo_quest()
	_show_current_decision()


func _quest_ids_era_corrente() -> Array:
	return QUEST_SEQUENZE.get(GameState.era_corrente, [])


func _prossima_quest_disponibile() -> Quest:
	for qid in _quest_ids_era_corrente():
		if GameState.quest_e_completata(qid):
			continue
		var q: Quest = QuestManager.quest_per_id(qid) as Quest
		if q != null and q.soddisfa_precondizioni():
			return q
	return null


func _quest_bloccata_da_stat() -> Quest:
	for qid in _quest_ids_era_corrente():
		if GameState.quest_e_completata(qid):
			continue
		var q: Quest = QuestManager.quest_per_id(qid) as Quest
		if q == null:
			continue
		var flag_ok: bool = true
		for flag in q.precondizioni_flag:
			if not GameState.has_flag(flag):
				flag_ok = false
				break
		if flag_ok and not q.soddisfa_precondizioni():
			return q
		return null
	return null


func _requisiti_testo(req: Dictionary) -> String:
	var parti: Array[String] = []
	for stat_name in req.keys():
		var etichetta: String = STAT_LABELS.get(stat_name, stat_name)
		parti.append("%s %d (hai %d)" % [etichetta, int(req[stat_name]), GameState.get_stat(stat_name)])
	return ", ".join(parti)


func _show_attesa_quest() -> void:
	in_attesa_quest = true
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	_show_narrative("")
	proposer_portrait.texture = null
	if event_image != null:
		event_image.visible = false
	proposer_name_label.modulate = COLOR_PROPOSER_NORMALE
	proposer_name_label.text = "Il consiglio attende"
	var bloccata: Quest = _quest_bloccata_da_stat()
	if bloccata != null:
		proposer_text_label.text = "%s\nServe ancora: %s" % [
			bloccata.descrizione_log, _requisiti_testo(bloccata.precondizioni_stat)
		]
		quest_log_label.text = "In attesa: %s\n(rafforza le stat richieste)" % bloccata.titolo
	else:
		proposer_text_label.text = "Le condizioni non sono ancora mature."
		quest_log_label.text = "In attesa"


func _show_transizione_a_era2() -> void:
	in_attesa_quest = false
	in_transizione_era = true
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	_set_decision_visible(false)
	call_button.visible = false
	arriving_portrait.visible = false
	proposer_portrait.texture = null
	if event_image != null:
		event_image.visible = false
	quest_log_label.text = "Era 1 completata."
	_mostra_era_card(
		"Fine dell'Era Paleolitica",
		"Le stagioni passano, le pietre crescono, i nomi cambiano.\nL'Idolo del Fuoco arde ancora, ma ora sopra un tempio.\nIl popolo è diventato un Regno Mitico.",
		"Premi INVIO per attraversare le ere"
	)
	AudioManager.play_sfx("era_transition")


# Title card cinematografica a schermo pieno per la transizione d'era.
func _mostra_era_card(titolo: String, testo: String, footer: String) -> void:
	_chiudi_era_card()
	era_card = CanvasLayer.new()
	era_card.layer = 15
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.015, 0.01, 0.02, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	era_card.add_child(bg)
	# Alone caldo al centro: il quasi-nero respira invece di sembrare un fade rotto.
	var alone_grad: Gradient = Gradient.new()
	alone_grad.colors = PackedColorArray([Color(0.16, 0.10, 0.04, 0.30), Color(0, 0, 0, 0.0)])
	alone_grad.offsets = PackedFloat32Array([0.0, 1.0])
	var alone_tex: GradientTexture2D = GradientTexture2D.new()
	alone_tex.gradient = alone_grad
	alone_tex.fill = GradientTexture2D.FILL_RADIAL
	alone_tex.fill_from = Vector2(0.5, 0.45)
	alone_tex.fill_to = Vector2(0.5, 1.1)
	alone_tex.width = 512
	alone_tex.height = 512
	var alone: TextureRect = TextureRect.new()
	alone.texture = alone_tex
	alone.set_anchors_preset(Control.PRESET_FULL_RECT)
	alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alone.stretch_mode = TextureRect.STRETCH_SCALE
	bg.add_child(alone)
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and in_transizione_era:
			_entra_era2())
	var titolo_lbl: Label = Label.new()
	titolo_lbl.text = titolo
	titolo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo_lbl.add_theme_font_size_override("font_size", 58)
	titolo_lbl.add_theme_color_override("font_color", Color(0.92, 0.8, 0.55))
	var fnt: Font = _font_titoli()
	if fnt != null:
		titolo_lbl.add_theme_font_override("font", fnt)
	titolo_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titolo_lbl.offset_top = 330
	titolo_lbl.offset_bottom = 430
	era_card.add_child(titolo_lbl)
	var testo_lbl: Label = Label.new()
	testo_lbl.text = testo
	testo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	testo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	testo_lbl.add_theme_font_size_override("font_size", 26)
	testo_lbl.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	testo_lbl.add_theme_constant_override("line_spacing", 10)
	testo_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	testo_lbl.offset_left = 420
	testo_lbl.offset_right = -420
	testo_lbl.offset_top = 480
	testo_lbl.offset_bottom = 660
	era_card.add_child(testo_lbl)
	var footer_lbl: Label = Label.new()
	footer_lbl.text = footer
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_font_size_override("font_size", 19)
	footer_lbl.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
	footer_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_lbl.offset_top = -120
	footer_lbl.offset_bottom = -80
	era_card.add_child(footer_lbl)
	add_child(era_card)
	# fade-in del nero + testi a cascata, footer che respira
	bg.modulate.a = 0.0
	titolo_lbl.modulate.a = 0.0
	testo_lbl.modulate.a = 0.0
	footer_lbl.modulate.a = 0.0
	var t: Tween = create_tween()
	t.tween_property(bg, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(titolo_lbl, "modulate:a", 1.0, 1.0).set_delay(0.6)
	t.parallel().tween_property(testo_lbl, "modulate:a", 1.0, 1.0).set_delay(1.3)
	t.parallel().tween_property(footer_lbl, "modulate:a", 0.9, 0.8).set_delay(2.0)
	var blink: Tween = create_tween()
	blink.set_loops()
	blink.set_trans(Tween.TRANS_SINE)
	blink.tween_interval(2.8)
	blink.tween_property(footer_lbl, "modulate:a", 0.45, 0.9)
	blink.tween_property(footer_lbl, "modulate:a", 0.9, 0.9)
	era_card.set_meta("blink", blink)


func _chiudi_era_card() -> void:
	if era_card != null and is_instance_valid(era_card):
		if era_card.has_meta("blink"):
			var b: Tween = era_card.get_meta("blink")
			if b != null and b.is_valid():
				b.kill()
		era_card.queue_free()
	era_card = null


func _entra_era2() -> void:
	in_transizione_era = false
	_chiudi_era_card()
	Ledger.unlock_artefatto("pietra_del_fuoco")
	GameState.avanza_era()
	_aggiorna_sfondo_era()
	var bg: ColorRect = $UI/Background
	if bg != null and not GameState.mystery_attiva:
		var t: Tween = create_tween()
		t.tween_property(bg, "color", COLOR_BG_ERA2, 1.0)
	_mostra_mappa_mondo(
		1, 2,
		"Il mondo cambia",
		"Dal Paleolitico al Regno Mitico: confini, regni e province prendono forma sulla terra."
	)


func _mostra_mappa_mondo(da_era: int, a_era: int, titolo: String, sottotitolo: String) -> void:
	var mappa: CanvasLayer = WORLD_MAP_SCENE.instantiate()
	mappa.configura(da_era, a_era, titolo, sottotitolo)
	mappa.chiuso.connect(_avvia_prossima_quest, CONNECT_ONE_SHOT)
	add_child(mappa)


func _show_ending() -> void:
	in_attesa_quest = false
	in_transizione_era = false
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	proposer_portrait.texture = null
	if event_image != null:
		event_image.visible = false
	proposer_name_label.modulate = COLOR_PROPOSER_NORMALE
	var finale: Finale = _valuta_finale()
	if finale != null:
		Ledger.unlock_lore("epilogo_" + finale.id)
		Ledger.unlock_artefatto("occhio_dello_spirito")
		if finale.id == "fine_guerra":
			Ledger.unlock_artefatto("corno_adunata")
		proposer_name_label.text = "Epilogo: %s" % finale.nome
		quest_log_label.text = "Era 2 completata.\nPremi R per ricominciare."
	else:
		proposer_name_label.text = "Epilogo"
	proposer_text_label.text = ""
	_show_narrative("Lo spirito ha preso la sua ultima decisione.")
	if ending_instance != null and is_instance_valid(ending_instance):
		ending_instance.queue_free()
	ending_instance = ENDING_SCENE.instantiate()
	ending_instance.finale = finale
	add_child(ending_instance)


func _valuta_finale() -> Finale:
	var finali: Array[Finale] = _carica_finali()
	if finali.is_empty():
		return null
	var migliore: Finale = null
	var miglior_punteggio: int = -1
	for f in finali:
		var s: int = f.match_score()
		if s > miglior_punteggio:
			miglior_punteggio = s
			migliore = f
	if migliore != null and miglior_punteggio >= 0:
		return migliore
	return _finale_fallback(finali)


func _carica_finali() -> Array[Finale]:
	var out: Array[Finale] = []
	var dir: DirAccess = DirAccess.open(FINALI_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var f: Finale = load(FINALI_DIR + fname) as Finale
			if f != null:
				out.append(f)
		fname = dir.get_next()
	dir.list_dir_end()
	return out


func _finale_fallback(finali: Array[Finale]) -> Finale:
	# Nessun finale soddisfa le condizioni: scegli quello la cui stat dominante
	# è più alta nel giocatore (escludendo il finale mystery, che richiede la scelta).
	var migliore: Finale = null
	var miglior_valore: int = -1
	for f in finali:
		if f.id == "fine_futura":
			continue
		var somma: int = 0
		for stat_name in f.condizioni_stat.keys():
			somma += GameState.get_stat(stat_name)
		if somma > miglior_valore:
			miglior_valore = somma
			migliore = f
	return migliore


func _show_current_decision() -> void:
	_clear_children(consiglieri_row)
	_clear_children(decision_panel_row)
	_show_narrative("")
	if current_quest == null:
		return
	quest_log_label.text = "Quest: %s\n(passo %d/%d)" % [
		current_quest.titolo, current_step + 1, current_quest.passi.size()
	]
	if current_step >= current_quest.passi.size():
		_complete_quest()
		return
	var decision: Decision = current_quest.passi[current_step]
	if decision == null:
		push_error("Decision nulla allo step %d" % current_step)
		return
	var nome_base: String = decision.personaggio_id
	var proposer: Personaggio = personaggi_db.get(decision.personaggio_id)
	if proposer != null:
		proposer_portrait.texture = proposer.ritratto
		nome_base = "%s — %s" % [proposer.nome, proposer.archetipo]
	else:
		proposer_portrait.texture = null
	var prefisso: String = PREFISSO_TIPO.get(decision.tipo_decisione, "")
	proposer_name_label.text = prefisso + nome_base
	proposer_name_label.modulate = _colore_proposer(decision.tipo_decisione)
	proposer_text_label.text = decision.testo_consigliere
	_richiamo_pendente = _richiamo_per(decision.id)
	if richiamo_label != null:
		richiamo_label.text = ("↩ " + _richiamo_pendente) if _richiamo_pendente != "" else ""
	_imposta_event_image(decision.illustrazione_id)
	_setup_consiglieri_for_decision(decision)
	_setup_decision_panel_for_decision(decision)
	# La decisione e' pronta ma nascosta: il consigliere "arriva" e il pulsante
	# lampeggia. Si entra nella view-decisione solo cliccando.
	_set_decision_visible(false)
	_consigliere_in_arrivo(
		proposer.nome if proposer != null else "Un consigliere",
		proposer.ritratto if proposer != null else null
	)


func _decisione_attiva() -> Decision:
	if current_quest == null or current_step >= current_quest.passi.size():
		return null
	return current_quest.passi[current_step]


func _richiamo_per(decision_id: String) -> String:
	var lista: Array = RICHIAMI.get(decision_id, [])
	for r in lista:
		if GameState.scelta_di(r["decisione"]) == r["scelta"]:
			return r["testo"]
	return ""


func _imposta_event_image(illustrazione_id: String) -> void:
	if event_image == null:
		return
	if illustrazione_id == "":
		event_image.visible = false
		event_image.texture = null
		return
	var path: String = "res://Assets/art/eventi/%s.png" % illustrazione_id
	if ResourceLoader.exists(path):
		event_image.texture = load(path)
		event_image.visible = true
	else:
		event_image.visible = false


func _setup_consiglieri_for_decision(decision: Decision) -> void:
	var targets_accepts: Dictionary = {}
	for opt in decision.opzioni:
		if opt == null:
			continue
		var cid: String = opt.target_consigliere_id
		if cid == "":
			continue
		if not targets_accepts.has(cid):
			targets_accepts[cid] = []
		var sid: String = opt.strategia.id if opt.strategia != null else ""
		if sid != "" and sid not in targets_accepts[cid]:
			targets_accepts[cid].append(sid)
	_decision_accents.clear()
	var idx: int = 0
	for cid in targets_accepts.keys():
		var zone: Control = DROP_ZONE_SCENE.instantiate()
		zone.zone_id = cid
		var accent: Color = ACCENT_PALETTE[idx % ACCENT_PALETTE.size()]
		_decision_accents[cid] = accent
		zone.accent_color = accent
		idx += 1
		var pers: Personaggio = personaggi_db.get(cid)
		if pers != null:
			zone.label_text = "%s\n%s" % [pers.nome, pers.archetipo]
			zone.portrait_texture = pers.ritratto
		else:
			zone.label_text = cid
		var accepts: Array[String] = []
		for sid in targets_accepts[cid]:
			accepts.append(sid)
		zone.accepted_item_ids = accepts
		consiglieri_row.add_child(zone)
		zone.item_dropped.connect(_on_item_dropped)


func _setup_decision_panel_for_decision(decision: Decision) -> void:
	var items_creati: Array = []
	var hint_stat_attivo: bool = _artefatto_mostra_hint()
	for opt in decision.opzioni:
		if opt == null:
			continue
		var item: Control = DRAG_ITEM_SCENE.instantiate()
		var sid: String = opt.strategia.id if opt.strategia != null else ""
		item.item_id = sid
		item.label_text = opt.label_text
		if hint_stat_attivo:
			var stat_p: String = _stat_principale(opt.effetto)
			if stat_p != "":
				item.stat_hint_text = "✦ %s" % stat_p.capitalize()
		var tgt: Personaggio = personaggi_db.get(opt.target_consigliere_id)
		if tgt != null:
			var nome_tgt: String = tgt.nome.split(" ")[0]
			item.target_text = "→ %s" % nome_tgt
			item.hint_text = "Trascina su %s" % nome_tgt
			item.target_color = _decision_accents.get(opt.target_consigliere_id, item.target_color)
		item.icon_texture = opt.icona_drag
		item.feedback_text = opt.feedback_testo
		decision_panel_row.add_child(item)
		item.set_meta("option", opt)
		if not opt.is_disponibile():
			item.set_disabled(true, opt.motivo_indisponibilita())
		items_creati.append(item)
	# Anti-softlock: nessuna decisione deve restare senza opzioni giocabili.
	var tutte_bloccate: bool = not items_creati.is_empty()
	for it in items_creati:
		if not it.is_disabled():
			tutte_bloccate = false
			break
	if tutte_bloccate:
		push_warning("Tutte le opzioni bloccate dai prerequisiti: riabilito per evitare il vicolo cieco")
		for it in items_creati:
			it.set_disabled(false)


func _artefatto_mostra_hint() -> bool:
	if GameState.artefatto_equipaggiato == "":
		return false
	var art: Artefatto = load("res://data/artefatti/%s.tres" % GameState.artefatto_equipaggiato) as Artefatto
	return art != null and art.mostra_hint_stat


func _stat_principale(eff: Effect) -> String:
	# La stat col delta positivo maggiore: la "virtù" che l'azione rinforza.
	if eff == null:
		return ""
	var migliore: String = ""
	var valore_max: int = 0
	for stat_name in eff.stat_delta:
		var v: int = int(eff.stat_delta[stat_name])
		if v > valore_max:
			valore_max = v
			migliore = stat_name
	return migliore


func _on_item_dropped(data: Dictionary) -> void:
	if processing_drop:
		return
	processing_drop = true
	AudioManager.play_sfx("drop_success")
	var source_node: Control = data.get("source") as Control
	if source_node == null or not source_node.has_meta("option"):
		processing_drop = false
		return
	var option: DecisionOption = source_node.get_meta("option") as DecisionOption
	if option == null:
		processing_drop = false
		return
	# Registra la scelta per i richiami narrativi cross-era.
	var dec_attiva: Decision = _decisione_attiva()
	if dec_attiva != null:
		GameState.registra_scelta(dec_attiva.id, option.target_consigliere_id)
	GameState.apply_effect(option.effetto)
	# Il turno produce Risorse dal villaggio: ogni decisione alimenta l'economia.
	_produci_risorse()
	var tipo_cons: String = _tipo_conseguenza(option.effetto)
	# Chiudi la view-decisione: si torna al villaggio dove si vede la conseguenza.
	_chiudi_decisione_morbida()
	if village != null:
		village.applica_conseguenza(tipo_cons)
		if tipo_cons == "costruzione":
			var n: int = int(GameState.flag_narrativi.get("villaggio_n", 1)) + 1
			GameState.set_flag("villaggio_n", n)
	_screen_shake(tipo_cons)
	SaveSystem.save_run()
	_show_narrative(option.feedback_testo)
	if source_node.has_method("consume"):
		source_node.consume()
	await get_tree().create_timer(FEEDBACK_PAUSE_SEC).timeout
	if not is_inside_tree():
		processing_drop = false
		return
	current_step += 1
	_show_current_decision()
	processing_drop = false


func _tipo_conseguenza(eff: Effect) -> String:
	# Deduce il tipo di conseguenza da mostrare sul villaggio.
	if eff == null:
		return "neutro"
	var sd: Dictionary = eff.stat_delta
	for civ in eff.rapporti_civilta:
		if int(eff.rapporti_civilta[civ]) < 0:
			return "guerra"
	if int(sd.get("militare", 0)) >= 8:
		return "guerra"
	for civ in eff.rapporti_civilta:
		if int(eff.rapporti_civilta[civ]) > 0:
			return "alleanza"
	if int(sd.get("costruzione", 0)) > 0 or eff.popolazione_delta > 0:
		return "costruzione"
	if int(sd.get("scienza", 0)) > 0:
		return "scienza"
	if int(sd.get("tesoro", 0)) > 0:
		return "ricchezza"
	return "neutro"


func _complete_quest() -> void:
	if current_quest == null:
		return
	GameState.apply_effect(current_quest.effetto_completamento)
	QuestManager.completa_quest(current_quest)
	SaveSystem.save_run()
	AudioManager.play_sfx("quest_complete")
	current_quest = null
	_avvia_prossima_quest()


func _show_narrative(text: String) -> void:
	narrative_label.text = text
	if narrative_tween != null and narrative_tween.is_valid():
		narrative_tween.kill()
	if text.is_empty():
		narrative_label.modulate.a = 0.0
		return
	# Typewriter: il testo "si scrive" invece di apparire tutto insieme.
	narrative_label.modulate.a = 1.0
	narrative_label.visible_characters = 0
	narrative_tween = create_tween()
	narrative_tween.tween_method(
		func(v: float) -> void:
			if is_instance_valid(narrative_label):
				narrative_label.visible_characters = int(v),
		0.0,
		float(text.length()),
		text.length() / 45.0,
	)


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _on_stat_changed(nome: String, vecchio: int, nuovo: int) -> void:
	var label: Label = stat_value_labels.get(nome)
	if label == null:
		return
	if stat_tweens.has(nome) and stat_tweens[nome] != null:
		(stat_tweens[nome] as Tween).kill()
	var tween: Tween = create_tween()
	stat_tweens[nome] = tween
	tween.tween_method(
		func(value: float) -> void:
			if is_instance_valid(label):
				label.text = str(int(round(value))),
		float(vecchio),
		float(nuovo),
		STAT_TWEEN_DURATION,
	)
	var flash_color: Color = Color(0.6, 1.0, 0.6) if nuovo > vecchio else Color(1.0, 0.6, 0.6)
	label.modulate = flash_color
	var color_tween: Tween = create_tween()
	color_tween.tween_property(label, "modulate", Color.WHITE, STAT_TWEEN_DURATION + 0.2)
	# Il medaglione pulsa e un "+N"/"-N" galleggia via: l'occhio sa dove guardare.
	var icon: TextureRect = stat_icon_nodes.get(nome)
	if icon != null:
		icon.pivot_offset = icon.size * 0.5
		var pulse: Tween = create_tween()
		pulse.tween_property(icon, "scale", Vector2(1.22, 1.22), 0.1) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pulse.tween_property(icon, "scale", Vector2.ONE, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_stat_delta_float(label, nuovo - vecchio)
	AudioManager.play_sfx("stat_up" if nuovo > vecchio else "stat_down")
	if village != null and (nome == "popolo" or nome == "tesoro"):
		village.aggiorna_prosperita(GameState.popolo, GameState.tesoro)
	_refresh_disabled_options()
	_refresh_potenziabili()
	if in_attesa_quest:
		_avvia_prossima_quest()


func _stat_delta_float(label: Label, delta: int) -> void:
	if delta == 0:
		return
	var fl: Label = Label.new()
	fl.top_level = true
	fl.text = "%+d" % delta
	fl.add_theme_font_size_override("font_size", 16)
	fl.add_theme_color_override("font_color",
		Color(0.55, 1.0, 0.55) if delta > 0 else Color(1.0, 0.55, 0.5))
	fl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	fl.add_theme_constant_override("outline_size", 4)
	label.add_child(fl)
	fl.global_position = label.global_position + Vector2(label.size.x + 8.0, 0.0)
	var t: Tween = create_tween()
	t.set_parallel()
	t.tween_property(fl, "global_position:y", fl.global_position.y - 20.0, 0.9) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(fl, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(fl.queue_free)


func _screen_shake(tipo: String) -> void:
	# Vibrazione calibrata: la guerra colpisce, la costruzione assesta appena.
	var ampiezza: float
	match tipo:
		"guerra":
			ampiezza = 8.0
		"neutro":
			return
		_:
			ampiezza = 3.0
	var ui: CanvasLayer = $UI
	var t: Tween = create_tween()
	for i in range(4):
		var off: Vector2 = Vector2(
			randf_range(-ampiezza, ampiezza), randf_range(-ampiezza * 0.6, ampiezza * 0.6))
		t.tween_property(ui, "offset", off, 0.05)
	t.tween_property(ui, "offset", Vector2.ZERO, 0.08)


func _on_mystery_attivata() -> void:
	var bg: ColorRect = $UI/Background
	if bg != null:
		var t: Tween = create_tween()
		t.tween_property(bg, "color", COLOR_BG_MYSTERY, 1.5)
	Ledger.unlock_evento("fiume_rosso")
	Ledger.unlock_lore("lore_fiume_rosso")
	Ledger.unlock_artefatto("lacrima_di_lyssa")
	AudioManager.play_sfx("quest_complete")
	_refresh_effetti_duraturi()
	_show_narrative("Il fuoco arde di un rosso che non conosce. Oltre la fiamma, qualcosa ascolta.")


func _on_popolazione_changed(vecchio: int, nuovo: int) -> void:
	if popolazione_label == null:
		return
	popolazione_label.text = "Popolazione: %d" % nuovo
	var flash_color: Color = Color(0.6, 1.0, 0.6) if nuovo > vecchio else Color(1.0, 0.6, 0.6)
	popolazione_label.modulate = flash_color
	var tween: Tween = create_tween()
	tween.tween_property(popolazione_label, "modulate", Color.WHITE, STAT_TWEEN_DURATION + 0.2)


func _on_rapporto_changed(_civ_id: String, _vecchio: int, _nuovo: int) -> void:
	_refresh_rapporti()
	_refresh_effetti_duraturi()


func _refresh_rapporti() -> void:
	if rapporti_label == null or rapporti_box == null:
		return
	_clear_children(rapporti_box)
	var qualcuno: bool = false
	for civ_id in GameState.rapporti_civilta.keys():
		var valore: int = int(GameState.rapporti_civilta[civ_id])
		if valore == 0 and not CIV_LABELS.has(civ_id):
			continue
		qualcuno = true
		var nome: String = CIV_LABELS.get(civ_id, civ_id)
		var segno: String = "+" if valore > 0 else ""
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var face: TextureRect = TextureRect.new()
		face.custom_minimum_size = Vector2(38, 38)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var face_path: String = "res://Assets/art/ambasciatori/%s.png" % civ_id
		if ResourceLoader.exists(face_path):
			face.texture = load(face_path)
		row.add_child(face)
		var lbl: Label = Label.new()
		lbl.text = "%s\n%s%d" % [nome, segno, valore]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var col_val: Color = Color(0.6, 1.0, 0.6) if valore > 0 else (Color(1.0, 0.6, 0.6) if valore < 0 else Color(1, 1, 1, 0.8))
		lbl.add_theme_color_override("font_color", col_val)
		row.add_child(lbl)
		rapporti_box.add_child(row)
	rapporti_label.text = "Rapporti:" if qualcuno else ""


func _refresh_effetti_duraturi() -> void:
	if effetti_box == null:
		return
	_clear_children(effetti_box)
	var qualcosa: bool = false
	# Artefatto equipaggiato: ti potenzia per tutta la run.
	if GameState.artefatto_equipaggiato != "":
		var art: Artefatto = load(
			"res://data/artefatti/%s.tres" % GameState.artefatto_equipaggiato) as Artefatto
		if art != null:
			var tip: String = "Artefatto: %s" % art.nome
			if art.descrizione != "":
				tip += "\n%s" % art.descrizione
			effetti_box.add_child(_crea_badge(art.nome, COLOR_EFF_ARTEFATTO, art.icona, tip))
			qualcosa = true
	# Mistero desto: una presenza oltre la fiamma osserva le scelte.
	if GameState.mystery_attiva:
		effetti_box.add_child(_crea_badge(
			"Mistero desto", COLOR_EFF_MYSTERY, null,
			"Qualcosa oltre la fiamma osserva le tue scelte."))
		qualcosa = true
	# Patti e rotture: aggregati come "ti sostengono / ti minacciano".
	var alleati: int = 0
	var ostili: int = 0
	for civ_id in GameState.rapporti_civilta.keys():
		var v: int = int(GameState.rapporti_civilta[civ_id])
		if v >= SOGLIA_RAPPORTO:
			alleati += 1
		elif v <= -SOGLIA_RAPPORTO:
			ostili += 1
	if alleati > 0:
		effetti_box.add_child(_crea_badge(
			"Alleati ×%d" % alleati, COLOR_EFF_ALLEATO, null,
			"Civiltà legate da un patto: ti sostengono."))
		qualcosa = true
	if ostili > 0:
		effetti_box.add_child(_crea_badge(
			"Ostili ×%d" % ostili, COLOR_EFF_OSTILE, null,
			"Civiltà in rotta con te: una minaccia presente."))
		qualcosa = true
	effetti_label.text = "Effetti duraturi:" if qualcosa else ""
	effetti_label.visible = qualcosa


func _crea_badge(testo: String, colore: Color, icona: Texture2D, tooltip: String) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	pc.tooltip_text = tooltip
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(colore.r, colore.g, colore.b, 0.14)
	sb.border_color = Color(colore.r, colore.g, colore.b, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pc.add_theme_stylebox_override("panel", sb)
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	pc.add_child(hb)
	if icona != null:
		var ic: TextureRect = TextureRect.new()
		ic.custom_minimum_size = Vector2(22, 22)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture = icona
		hb.add_child(ic)
	var lbl: Label = Label.new()
	lbl.text = testo
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", colore.lightened(0.2))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl)
	return pc


func _colore_proposer(tipo: String) -> Color:
	match tipo:
		"catastrofe": return COLOR_PROPOSER_CATASTROFE
		"svolta": return COLOR_PROPOSER_SVOLTA
		"mistero": return COLOR_PROPOSER_MISTERO
		_: return COLOR_PROPOSER_NORMALE


func _refresh_disabled_options() -> void:
	for item in decision_panel_row.get_children():
		if not item.has_meta("option"):
			continue
		var opt: DecisionOption = item.get_meta("option") as DecisionOption
		if opt == null:
			continue
		if not item.has_method("set_disabled"):
			continue
		if opt.is_disponibile():
			item.set_disabled(false)
		else:
			item.set_disabled(true, opt.motivo_indisponibilita())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_L: _toggle_ledger()
		KEY_ENTER, KEY_KP_ENTER:
			if in_transizione_era:
				_entra_era2()
		KEY_ESCAPE: _on_escape()
		_:
			if OS.is_debug_build():
				_debug_input(event.keycode)


func _debug_input(keycode: int) -> void:
	match keycode:
		KEY_R: _reset_run()
		KEY_1: GameState.modifica_stat("militare", 5)
		KEY_2: GameState.modifica_stat("tesoro", 5)
		KEY_3: GameState.modifica_stat("diplomazia", 5)
		KEY_4: GameState.modifica_stat("scienza", 5)
		KEY_5: GameState.modifica_stat("legge", 5)
		KEY_6: GameState.modifica_stat("spionaggio", 5)
		KEY_7: GameState.modifica_stat("popolo", 5)
		KEY_8: GameState.modifica_stat("costruzione", 5)


func _on_escape() -> void:
	if edificio_panel != null and is_instance_valid(edificio_panel):
		_chiudi_pannello_edificio()
		return
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		_close_ledger_if_open()
		return
	_toggle_pause()


func _toggle_pause() -> void:
	if pause_instance != null and is_instance_valid(pause_instance):
		_close_pause()
		return
	pause_instance = PAUSE_SCENE.instantiate()
	pause_instance.connect("resumed", _close_pause)
	add_child(pause_instance)
	get_tree().paused = true


func _close_pause() -> void:
	get_tree().paused = false
	if pause_instance != null and is_instance_valid(pause_instance):
		pause_instance.queue_free()
		pause_instance = null


func _toggle_ledger() -> void:
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		_close_ledger_if_open()
	else:
		ledger_screen_instance = LEDGER_SCENE.instantiate()
		add_child(ledger_screen_instance)


func _close_ledger_if_open() -> void:
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		ledger_screen_instance.queue_free()
		ledger_screen_instance = null


# --- Villaggio migliorabile (D046) ------------------------------------------

func _on_edificio_cliccato(slot: int) -> void:
	# Solo nella vista villaggio: niente upgrade durante decisione/transizione/drop.
	if processing_drop or in_transizione_era:
		return
	if $UI/ConsigliereProposer.visible:
		return
	if edificio_panel != null and is_instance_valid(edificio_panel):
		return
	_apri_pannello_edificio(slot)


func _apri_pannello_edificio(slot: int) -> void:
	var era: int = GameState.era_corrente
	var tipo: int = village.tipo_at(slot)
	if tipo < 0:
		return
	var lv: int = GameState.livello_edificio(era, slot)
	var nome: String = EDIFICIO_NOME_ERA.get(era, {}).get(tipo, "Edificio")
	var stat: String = EDIFICIO_STAT_ERA.get(era, {}).get(tipo, "popolo")

	edificio_panel = CanvasLayer.new()
	edificio_panel.layer = 12
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_chiudi_pannello_edificio())
	edificio_panel.add_child(dim)

	var box: PanelContainer = PanelContainer.new()
	box.add_theme_stylebox_override("panel", _stile_pannello())
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -235.0
	box.offset_right = 235.0
	box.offset_top = -205.0
	box.offset_bottom = 205.0
	edificio_panel.add_child(box)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	box.add_child(vb)

	var titolo: Label = Label.new()
	var tfont: Font = _font_titoli()
	if tfont != null:
		titolo.add_theme_font_override("font", tfont)
	titolo.text = "%s — Livello %d" % [nome, lv]
	titolo.add_theme_font_size_override("font_size", 28)
	titolo.add_theme_color_override("font_color", Color(0.93, 0.82, 0.5))
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(titolo)

	var stat_lbl: Label = Label.new()
	stat_lbl.text = "Sviluppa: %s" % STAT_LABELS.get(stat, stat)
	stat_lbl.add_theme_font_size_override("font_size", 17)
	stat_lbl.add_theme_color_override("font_color", Color(0.82, 0.76, 0.62))
	stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stat_lbl)

	var sep: ColorRect = ColorRect.new()
	sep.color = Color(0.5, 0.38, 0.22, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	vb.add_child(sep)

	if lv >= GameState.EDIFICIO_LIVELLO_MAX:
		var maxlbl: Label = Label.new()
		maxlbl.text = "Già al massimo livello.\nIl popolo non sa costruire più in alto."
		maxlbl.add_theme_font_size_override("font_size", 17)
		maxlbl.add_theme_color_override("font_color", Color(0.72, 0.67, 0.55))
		maxlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(maxlbl)
	else:
		var next: int = lv + 1
		var costo: int = int(UPGRADE_COSTO[next])
		var gate: int = int(UPGRADE_GATE_COSTR[next])
		var bonus: int = int(UPGRADE_BONUS[next])
		var ok_risorse: bool = GameState.risorse >= costo
		var ok_gate: bool = GameState.get_stat("costruzione") >= gate
		var info: Label = Label.new()
		info.text = "Migliora a Livello %d:  +%d %s" % [next, bonus, STAT_LABELS.get(stat, stat)]
		info.add_theme_font_size_override("font_size", 18)
		info.add_theme_color_override("font_color", Color(0.9, 0.86, 0.74))
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(info)
		var costo_lbl: Label = Label.new()
		costo_lbl.text = "Costo: %d Risorse  (hai %d)" % [costo, GameState.risorse]
		costo_lbl.add_theme_font_size_override("font_size", 16)
		costo_lbl.add_theme_color_override("font_color",
			Color(0.6, 1, 0.6) if ok_risorse else Color(1, 0.6, 0.55))
		costo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(costo_lbl)
		var gate_lbl: Label = Label.new()
		gate_lbl.text = "Richiede Costruzione ≥ %d  (hai %d)" % [gate, GameState.get_stat("costruzione")]
		gate_lbl.add_theme_font_size_override("font_size", 16)
		gate_lbl.add_theme_color_override("font_color",
			Color(0.6, 1, 0.6) if ok_gate else Color(1, 0.6, 0.55))
		gate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(gate_lbl)
		var migliora_btn: Button = Button.new()
		migliora_btn.text = "Migliora"
		migliora_btn.disabled = not (ok_risorse and ok_gate)
		migliora_btn.pressed.connect(func() -> void:
			_esegui_upgrade(era, slot, stat, costo, bonus))
		vb.add_child(migliora_btn)

	var chiudi: Button = Button.new()
	chiudi.text = "Chiudi"
	chiudi.pressed.connect(_chiudi_pannello_edificio)
	vb.add_child(chiudi)

	add_child(edificio_panel)


func _esegui_upgrade(era: int, slot: int, stat: String, costo: int, bonus: int) -> void:
	if GameState.risorse < costo:
		return
	GameState.modifica_risorse(-costo)
	GameState.modifica_stat(stat, bonus)
	GameState.migliora_edificio(era, slot)
	AudioManager.play_sfx("quest_complete")
	SaveSystem.save_run()
	_refresh_potenziabili()
	_chiudi_pannello_edificio()


func _chiudi_pannello_edificio() -> void:
	if edificio_panel != null and is_instance_valid(edificio_panel):
		edificio_panel.queue_free()
	edificio_panel = null


# Accende il glow d'invito sugli edifici che il giocatore può migliorare ORA
# (Risorse e Costruzione sufficienti). Discoverability: la meccanica si fa notare.
func _refresh_potenziabili() -> void:
	if village == null or village.slot_count() == 0:
		return
	var era: int = GameState.era_corrente
	var risorse: int = GameState.risorse
	var costr: int = GameState.get_stat("costruzione")
	var slots: Array = []
	for s in range(village.slot_count()):
		var lv: int = GameState.livello_edificio(era, s)
		if lv >= GameState.EDIFICIO_LIVELLO_MAX:
			continue
		var nx: int = lv + 1
		if risorse >= int(UPGRADE_COSTO[nx]) and costr >= int(UPGRADE_GATE_COSTR[nx]):
			slots.append(s)
	village.segna_potenziabili(slots)
	_aggiorna_produzione_label()


# Risorse prodotte a ogni decisione (turno): base + somma dei livelli edificio,
# doppia per gli edifici economici. Piu' il villaggio cresce, piu' rende.
func _produzione_per_turno() -> int:
	if village == null:
		return PRODUZIONE_BASE
	var era: int = GameState.era_corrente
	var tot: int = PRODUZIONE_BASE
	for s in range(village.slot_count()):
		var lv: int = GameState.livello_edificio(era, s)
		var tipo: int = village.tipo_at(s)
		var mult: int = 2 if bool(EDIFICIO_ECONOMICO.get(era, {}).get(tipo, false)) else 1
		tot += lv * mult
	return tot


func _produci_risorse() -> void:
	var n: int = _produzione_per_turno()
	if n > 0:
		GameState.modifica_risorse(n)
		_float_risorse(n)


# "+N" verde che sale dalla barra risorse: il turno ha alimentato l'economia.
func _float_risorse(n: int) -> void:
	if risorse_label == null or not is_instance_valid(risorse_label):
		return
	var fl: Label = Label.new()
	fl.top_level = true
	fl.text = "+%d" % n
	fl.add_theme_font_size_override("font_size", 22)
	fl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	fl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	fl.add_theme_constant_override("outline_size", 4)
	$UI.add_child(fl)
	fl.global_position = risorse_label.global_position + Vector2(risorse_label.size.x + 12.0, 4.0)
	var t: Tween = create_tween()
	t.set_parallel()
	t.tween_property(fl, "global_position:y", fl.global_position.y - 28.0, 1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(fl, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(fl.queue_free)


# Barra risorse in alto: identità "gestionale" del gioco (Risorse + produzione/turno).
func _setup_resource_bar() -> void:
	var bar: PanelContainer = PanelContainer.new()
	bar.name = "ResourceBar"
	bar.add_theme_stylebox_override("panel", _stile_pannello())
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.offset_left = -300.0
	bar.offset_right = 300.0
	bar.offset_top = 14.0
	bar.offset_bottom = 74.0
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hb)
	var ic: TextureRect = TextureRect.new()
	ic.custom_minimum_size = Vector2(30, 30)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icp: String = STAT_ICON_DIR + "costruzione.png"
	if ResourceLoader.exists(icp):
		ic.texture = load(icp)
	hb.add_child(ic)
	risorse_label = Label.new()
	risorse_label.text = "Risorse: %d" % GameState.risorse
	risorse_label.add_theme_font_size_override("font_size", 22)
	risorse_label.add_theme_color_override("font_color", Color(0.97, 0.86, 0.5))
	risorse_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	risorse_label.add_theme_constant_override("outline_size", 4)
	var tf: Font = _font_titoli()
	if tf != null:
		risorse_label.add_theme_font_override("font", tf)
	hb.add_child(risorse_label)
	produzione_label = Label.new()
	produzione_label.text = "(+%d / turno)" % _produzione_per_turno()
	produzione_label.add_theme_font_size_override("font_size", 15)
	produzione_label.add_theme_color_override("font_color", Color(0.62, 0.92, 0.62))
	produzione_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(produzione_label)
	var sep: VSeparator = VSeparator.new()
	hb.add_child(sep)
	var hint: Label = Label.new()
	hint.text = "Costruisci e potenzia il villaggio"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.78, 0.72, 0.6))
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(hint)
	$UI.add_child(bar)


func _aggiorna_produzione_label() -> void:
	if produzione_label != null:
		produzione_label.text = "(+%d / turno)" % _produzione_per_turno()


func _on_risorse_changed(vecchio: int, nuovo: int) -> void:
	if risorse_label == null:
		return
	risorse_label.text = "Risorse: %d" % nuovo
	risorse_label.modulate = Color(0.6, 1, 0.6) if nuovo > vecchio else Color(1, 0.7, 0.5)
	var t: Tween = create_tween()
	t.tween_property(risorse_label, "modulate", Color.WHITE, 0.6)
	_aggiorna_produzione_label()


func _on_plot_cliccato(slot: int) -> void:
	if processing_drop or in_transizione_era:
		return
	if $UI/ConsigliereProposer.visible:
		return
	if edificio_panel != null and is_instance_valid(edificio_panel):
		return
	_apri_pannello_costruzione(slot)


func _apri_pannello_costruzione(slot: int) -> void:
	var era: int = GameState.era_corrente
	var tipo: int = village.tipo_previsto(slot)
	if tipo < 0:
		return
	var nome: String = EDIFICIO_NOME_ERA.get(era, {}).get(tipo, "Edificio")
	var stat: String = EDIFICIO_STAT_ERA.get(era, {}).get(tipo, "popolo")
	var ok_risorse: bool = GameState.risorse >= BUILD_COSTO
	var ok_gate: bool = GameState.get_stat("costruzione") >= BUILD_GATE_COSTR
	var vb: VBoxContainer = _nuovo_pannello_modale()
	vb.add_child(_lbl_titolo("Costruisci: %s" % nome))
	vb.add_child(_lbl("Sviluppa: %s" % STAT_LABELS.get(stat, stat), 17, Color(0.82, 0.76, 0.62)))
	vb.add_child(_separatore_panel())
	vb.add_child(_lbl("Nuovo edificio del villaggio:  +%d %s" % [BUILD_BONUS, STAT_LABELS.get(stat, stat)],
		18, Color(0.9, 0.86, 0.74)))
	vb.add_child(_lbl("Costo: %d Risorse  (hai %d)" % [BUILD_COSTO, GameState.risorse],
		16, Color(0.6, 1, 0.6) if ok_risorse else Color(1, 0.6, 0.55)))
	vb.add_child(_lbl("Richiede Costruzione ≥ %d  (hai %d)" % [BUILD_GATE_COSTR, GameState.get_stat("costruzione")],
		16, Color(0.6, 1, 0.6) if ok_gate else Color(1, 0.6, 0.55)))
	var btn: Button = Button.new()
	btn.text = "Costruisci"
	btn.disabled = not (ok_risorse and ok_gate)
	btn.pressed.connect(func() -> void: _esegui_build(era, stat))
	vb.add_child(btn)
	var chiudi: Button = Button.new()
	chiudi.text = "Chiudi"
	chiudi.pressed.connect(_chiudi_pannello_edificio)
	vb.add_child(chiudi)
	add_child(edificio_panel)


func _esegui_build(_era: int, stat: String) -> void:
	if GameState.risorse < BUILD_COSTO:
		return
	if village.slot_count() >= village.slot_max():
		return
	GameState.modifica_risorse(-BUILD_COSTO)
	if stat != "":
		GameState.modifica_stat(stat, BUILD_BONUS)
	village.costruisci()
	GameState.set_flag("villaggio_n", village.slot_count())
	AudioManager.play_sfx("quest_complete")
	SaveSystem.save_run()
	_refresh_potenziabili()
	_chiudi_pannello_edificio()


func _nuovo_pannello_modale() -> VBoxContainer:
	edificio_panel = CanvasLayer.new()
	edificio_panel.layer = 12
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_chiudi_pannello_edificio())
	edificio_panel.add_child(dim)
	var box: PanelContainer = PanelContainer.new()
	box.add_theme_stylebox_override("panel", _stile_pannello())
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -235.0
	box.offset_right = 235.0
	box.offset_top = -205.0
	box.offset_bottom = 205.0
	edificio_panel.add_child(box)
	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	box.add_child(vb)
	return vb


func _lbl(testo: String, dim_font: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", dim_font)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _lbl_titolo(testo: String) -> Label:
	var l: Label = _lbl(testo, 28, Color(0.93, 0.82, 0.5))
	var f: Font = _font_titoli()
	if f != null:
		l.add_theme_font_override("font", f)
	return l


func _separatore_panel() -> ColorRect:
	var sep: ColorRect = ColorRect.new()
	sep.color = Color(0.5, 0.38, 0.22, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _reset_run() -> void:
	GameState.reset_run()
	_show_narrative("")
	in_transizione_era = false
	if ending_instance != null and is_instance_valid(ending_instance):
		ending_instance.queue_free()
		ending_instance = null
	var bg: ColorRect = $UI/Background
	if bg != null:
		bg.color = COLOR_BG_ERA1
	_refresh_rapporti()
	_refresh_effetti_duraturi()
	_start_era1()
