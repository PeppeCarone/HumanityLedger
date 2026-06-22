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

# J8: ultimo valore mostrato per civiltà, per accendere il flash solo su ciò che cambia.
var _rapporti_prec: Dictionary = {}

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
var stat_bar_fills: Dictionary = {}   # barra 0–100 per ogni stat (colpo d'occhio sulla forza)
var narrative_tween: Tween = null
var in_attesa_quest: bool = false
var in_transizione_era: bool = false
var atmosfera: CPUParticles2D = null
var edificio_panel: CanvasLayer = null
var siege_instance: CanvasLayer = null
var _idle_decisione_tweens: Array[Tween] = []
var _godray: Control = null
var _vignette: ColorRect = null
var _vignette_tween: Tween = null


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
	# Più aria tra le righe + a-capo morbido: i testi lunghi respirano e si leggono meglio.
	proposer_text_label.add_theme_constant_override("line_spacing", 11)
	proposer_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if is_instance_valid(village):
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
	if mostra:
		_avvia_idle_decisione()
	else:
		_ferma_idle_decisione()


# Vita nella vista decisione (procedurale, nessun asset): il ritratto del proponente
# "respira" e lo sfondo dipinto fa un lentissimo zoom (Ken Burns). Si ferma e si azzera
# tornando al villaggio (dove lo sfondo è il tabellone 1:1).
func _avvia_idle_decisione() -> void:
	_ferma_idle_decisione()
	if proposer_portrait != null and is_instance_valid(proposer_portrait):
		proposer_portrait.pivot_offset = proposer_portrait.size * Vector2(0.5, 1.0)
		var pt: Tween = create_tween()
		pt.set_loops()
		pt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pt.tween_property(proposer_portrait, "scale", Vector2(1.012, 1.012), 2.2)
		pt.tween_property(proposer_portrait, "scale", Vector2.ONE, 2.2)
		_idle_decisione_tweens.append(pt)
	# Ken Burns sullo sfondo DIPINTO della decisione (decision_bg, quello visibile: copre
	# scene_bg). In caverna aggiunge anche dei raggi di luce che ondeggiano (godrays).
	if decision_bg != null and is_instance_valid(decision_bg):
		decision_bg.pivot_offset = decision_bg.size * 0.5
		var bt: Tween = create_tween()
		bt.set_loops()
		bt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bt.tween_property(decision_bg, "scale", Vector2(1.06, 1.06), 11.0)
		bt.tween_property(decision_bg, "scale", Vector2(1.02, 1.02), 11.0)
		_idle_decisione_tweens.append(bt)
		if _scena_corrente() == BG_CAVERNA:
			_crea_godray()
	# J12: col mystery desto, la vignette della vista decisione vira a un viola tenue —
	# segnale ambientale "qualcosa non torna", senza una parola di testo.
	if GameState.mystery_attiva:
		_vira_vignette(Color(0.16, 0.04, 0.22, 1.0), 0.46, 1.4)


func _ferma_idle_decisione() -> void:
	# Tornando al villaggio la vignette ridiventa neutra (annulla J12).
	_vira_vignette(Color(0, 0, 0, 1.0), 0.36, 0.9)
	for t in _idle_decisione_tweens:
		if t != null and t.is_valid():
			t.kill()
	_idle_decisione_tweens.clear()
	if proposer_portrait != null and is_instance_valid(proposer_portrait):
		proposer_portrait.scale = Vector2.ONE
	if decision_bg != null and is_instance_valid(decision_bg):
		decision_bg.scale = Vector2.ONE
	if _godray != null and is_instance_valid(_godray):
		_godray.queue_free()
	_godray = null


# Anima la tinta+intensita' della vignette (J12). No-op sicuro se manca shader/materiale.
func _vira_vignette(tint: Color, intensity: float, dur: float) -> void:
	if _vignette == null or not is_instance_valid(_vignette):
		return
	var mat: ShaderMaterial = _vignette.material as ShaderMaterial
	if mat == null:
		return
	if _vignette_tween != null and _vignette_tween.is_valid():
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	_vignette_tween.tween_property(mat, "shader_parameter/tint", tint, dur)
	_vignette_tween.tween_property(mat, "shader_parameter/intensity", intensity, dur)


# Raggio di luce dall'alto (godray) nella caverna: fascio caldo che ondeggia piano,
# come polvere illuminata che scende dall'apertura. Additivo, tenue. Niente asset.
func _crea_godray() -> void:
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 8
	var beam: TextureRect = TextureRect.new()
	beam.texture = tex
	beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam.stretch_mode = TextureRect.STRETCH_SCALE
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp: Vector2 = get_viewport().get_visible_rect().size
	beam.size = Vector2(vp.x * 0.24, vp.y * 1.25)
	beam.pivot_offset = Vector2(beam.size.x * 0.5, 0.0)
	# Spostato a destra: l'area caverna visibile (il centro è coperto dal pannello proponente).
	beam.position = Vector2(vp.x * 0.80 - beam.size.x * 0.5, -vp.y * 0.12)
	beam.rotation = deg_to_rad(13.0)
	beam.modulate = Color(1.0, 0.92, 0.68, 0.0)
	if decision_bg != null and is_instance_valid(decision_bg):
		decision_bg.add_child(beam)
	else:
		$UI.add_child(beam)
	_godray = beam
	var t: Tween = beam.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(beam, "modulate:a", 0.16, 3.0)
	t.parallel().tween_property(beam, "rotation", deg_to_rad(16.0), 3.0)
	t.tween_property(beam, "modulate:a", 0.07, 3.0)
	t.parallel().tween_property(beam, "rotation", deg_to_rad(11.0), 3.0)


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
	# Vignettatura cinematografica (shader riusabile): angoli scuriti, centro pulito. Sta
	# sopra tutta la UI di scena (i CanvasLayer di pausa/ledger restano comunque sopra).
	# La tinta vira al viola durante la vista decisione col mystery attivo (J12).
	_vignette = UiStyle.crea_vignette(0.36, Color(0, 0, 0, 1))
	_vignette.name = "Vignette"
	$UI.add_child(_vignette)


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
	# Pannelli sempre-visibili: stile PULITO (non la cornice ornata, che qui affolla e si
	# stira). La cornice ricca resta ai modali (vedi _nuovo_pannello_modale).
	for node_path in ["UI/HUDPanel", "UI/ConsigliereProposer", "UI/DecisionPanel"]:
		var panel: Control = get_node_or_null(node_path)
		if panel == null:
			continue
		panel.add_theme_stylebox_override("panel", UiStyle.panel_clean())


func _stile_pannello() -> StyleBox:
	# Cornice centralizzata in UiStyle: usa la texture §8a se presente in Assets/art/ui/,
	# altrimenti il bronzo a codice (fallback identico). Vedi Docs/13-redesign-estetico.md.
	return UiStyle.panel_stylebox()


func _setup_hud() -> void:
	stat_value_labels.clear()
	stat_icon_nodes.clear()
	stat_bar_fills.clear()
	for stat_name in GameState.STAT_NAMES:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icon_path: String = STAT_ICON_DIR + stat_name + ".png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		row.add_child(icon)
		stat_icon_nodes[stat_name] = icon
		# Colonna: riga "nome … valore" + barra 0–100. Da pannello di comando, non da debug.
		var col: VBoxContainer = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_theme_constant_override("separation", 3)
		row.add_child(col)
		var topline: HBoxContainer = HBoxContainer.new()
		topline.add_theme_constant_override("separation", 6)
		col.add_child(topline)
		var nome_lbl: Label = Label.new()
		nome_lbl.text = STAT_LABELS[stat_name]
		nome_lbl.add_theme_font_size_override("font_size", 15)
		nome_lbl.add_theme_color_override("font_color", Color(0.80, 0.73, 0.60))
		nome_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		topline.add_child(nome_lbl)
		var label: Label = Label.new()
		label.name = "Stat_" + stat_name
		label.text = str(GameState.get_stat(stat_name))
		label.add_theme_font_size_override("font_size", 19)
		label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
		label.custom_minimum_size = Vector2(30, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		topline.add_child(label)
		stat_value_labels[stat_name] = label
		var track: ColorRect = ColorRect.new()
		track.color = Color(0.17, 0.13, 0.09, 0.9)
		track.custom_minimum_size = Vector2(0, 6)
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(track)
		var fill: ColorRect = ColorRect.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)
		stat_bar_fills[stat_name] = fill
		_aggiorna_barra_stat(stat_name, GameState.get_stat(stat_name))
		hud_container.add_child(row)
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
	tasti.text = "Clicca un edificio per migliorarlo\nV  Villaggio      L  Ledger      ESC  Pausa"
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
	if is_instance_valid(village):
		var n: int = int(GameState.flag_narrativi.get("villaggio_n", 1))
		village.sincronizza(GameState.era_corrente, n)
		village.aggiorna_prosperita(GameState.popolo, GameState.tesoro)
		_refresh_potenziabili()
		_refresh_bandiere_alleati()


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
		# Fine era: prima della transizione c'e' L'Assedio (boss fight TD), una volta
		# sola per era. Vedi Docs/11-boss-fight.md. Superato l'Assedio si prosegue.
		if GameState.era_corrente == 1 and GameState.has_flag("era1_completata"):
			if not GameState.has_flag("era1_assedio_fatto"):
				_avvia_assedio(1)
			else:
				_show_transizione_a_era2()
		elif GameState.era_corrente == 2 and GameState.has_flag("era2_completata"):
			if not GameState.has_flag("era2_assedio_fatto"):
				_avvia_assedio(2)
			else:
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


# --- L'Assedio (boss fight TD di fine era) ----------------------------------

func _avvia_assedio(era: int) -> void:
	if siege_instance != null and is_instance_valid(siege_instance):
		return
	_set_decision_visible(false)
	call_button.visible = false
	arriving_portrait.visible = false
	# Title-card che prepara al cambio di genere (gestionale → difesa) prima dell'Assedio.
	_mostra_card_assedio(era)


# Cartello di transizione: avvisa che ora si difende il villaggio, poi istanzia l'Assedio
# sotto la card e la dissolve per rivelarlo. Riduce lo spaesamento alla prima volta.
func _mostra_card_assedio(era: int) -> void:
	var card: CanvasLayer = CanvasLayer.new()
	card.layer = 25
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.012, 0.02, 0.93)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(vb)
	var t1: Label = Label.new()
	t1.text = "L'ASSEDIO"
	t1.add_theme_font_size_override("font_size", 64)
	t1.add_theme_color_override("font_color", Color(0.92, 0.6, 0.42))
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	t1.add_theme_constant_override("outline_size", 6)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tf: Font = _font_titoli()
	if tf != null:
		t1.add_theme_font_override("font", tf)
	vb.add_child(t1)
	var t2: Label = Label.new()
	t2.text = "Il villaggio è sotto attacco — difendilo.\nLe stat che hai coltivato diventano il tuo esercito."
	t2.add_theme_font_size_override("font_size", 22)
	t2.add_theme_color_override("font_color", Color(0.86, 0.8, 0.66))
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	t2.add_theme_constant_override("outline_size", 4)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	add_child(card)
	root.modulate.a = 0.0
	AudioManager.play_sfx("stat_down")
	var t: Tween = create_tween()
	t.tween_property(root, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	t.tween_interval(1.4)
	t.tween_callback(_istanzia_assedio.bind(era))
	t.tween_property(root, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(card.queue_free)


func _istanzia_assedio(era: int) -> void:
	if siege_instance != null and is_instance_valid(siege_instance):
		return
	siege_instance = SiegeArena.new()
	siege_instance.configura(era)   # PRIMA di add_child: legge le stat della run
	siege_instance.assedio_concluso.connect(_on_assedio_concluso.bind(era), CONNECT_ONE_SHOT)
	add_child(siege_instance)


func _on_assedio_concluso(esito: String, era: int) -> void:
	GameState.set_flag("era%d_assedio_fatto" % era, true)
	GameState.flag_narrativi["era%d_assedio_esito" % era] = esito
	if siege_instance != null and is_instance_valid(siege_instance):
		siege_instance.queue_free()
	siege_instance = null
	_applica_esito_assedio(esito)
	SaveSystem.save_run()
	_avvia_prossima_quest()


# Ricompense / conseguenze dell'Assedio (Fase F). No game over (D024): anche "sopraffatto"
# avanza. La vittoria sblocca il "Trofeo dell'Assedio" nel Ledger; l'immacolata una lore
# rara; la sconfitta una lore cupa + un contraccolpo da ricostruire (mai azzera i progressi).
func _applica_esito_assedio(esito: String) -> void:
	var nota: String = ""
	match esito:
		"immacolata":
			GameState.modifica_risorse(28)
			GameState.modifica_stat("costruzione", 5)
			GameState.modifica_stat("popolo", 4)
			Ledger.unlock_lore("lore_trofeo_assedio")
			Ledger.unlock_lore("lore_assedio_immacolato")
			nota = "Difesa immacolata: il popolo esce dall'assedio più forte di prima.\n+28 Risorse · +5 Costruzione · +4 Popolo"
		"trionfo":
			GameState.modifica_risorse(16)
			GameState.modifica_stat("costruzione", 3)
			Ledger.unlock_lore("lore_trofeo_assedio")
			nota = "Il villaggio ha retto.\n+16 Risorse · +3 Costruzione"
		"fatica":
			GameState.modifica_risorse(8)
			GameState.modifica_popolazione(-4)
			Ledger.unlock_lore("lore_trofeo_assedio")
			nota = "Vittoria a caro prezzo.\n+8 Risorse · −4 Popolazione"
		"sopraffatto":
			GameState.modifica_popolazione(-8)
			Ledger.unlock_lore("lore_assedio_sopraffatto")
			var crollato: String = _danneggia_edificio_assedio()
			nota = "Le mura hanno ceduto: −8 Popolazione."
			if crollato != "":
				nota += "\n%s crolla di un livello: andrà ricostruito." % crollato
	if nota != "":
		_toast_traguardo("L'Assedio" if esito != "sopraffatto" else "Dopo l'Assedio", nota)


# Sciagura dell'Assedio sopraffatto: abbatte di un livello un edificio già migliorato
# (mai sotto 1). Riusa la logica delle catastrofi. Ritorna il nome dell'edificio o "".
func _danneggia_edificio_assedio() -> String:
	if village == null:
		return ""
	var era: int = GameState.era_corrente
	var candidati: Array = []
	for s in range(village.slot_count()):
		if GameState.livello_edificio(era, s) > 1:
			candidati.append(s)
	if candidati.is_empty():
		return ""
	var slot: int = candidati[randi() % candidati.size()]
	var tipo: int = village.tipo_at(slot)
	GameState.danneggia_edificio(era, slot)
	village.danneggia(slot)
	return EDIFICIO_NOME_ERA.get(era, {}).get(tipo, "Un edificio")


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
	# J13: impact-frame al drop — lampo bianco + micro-pausa (niente Engine.time_scale)
	# perche' la scelta "atterri" con peso prima che il mondo reagisca.
	_flash_drop()
	await get_tree().create_timer(0.06).timeout
	if not is_inside_tree():
		processing_drop = false
		return
	if is_instance_valid(village):
		village.applica_conseguenza(tipo_cons, _intensita_conseguenza(option.effetto))
		if tipo_cons == "costruzione":
			var n: int = int(GameState.flag_narrativi.get("villaggio_n", 1)) + 1
			GameState.set_flag("villaggio_n", n)
	_screen_shake(tipo_cons)
	var nota_danno: String = _check_danno_catastrofe(option.effetto)
	SaveSystem.save_run()
	_show_narrative(option.feedback_testo + nota_danno)
	if source_node.has_method("consume"):
		source_node.consume()
	await get_tree().create_timer(FEEDBACK_PAUSE_SEC).timeout
	if not is_inside_tree():
		processing_drop = false
		return
	current_step += 1
	_show_current_decision()
	processing_drop = false


func _intensita_conseguenza(eff: Effect) -> float:
	# J7: intensità del burst dal cambiamento più grande della scelta (stat, rapporti,
	# popolazione). Delta tipici 3–12 → fattore ~0.99–1.40; svolte estreme fino a ~1.6.
	if eff == null:
		return 1.0
	var m: int = 0
	for k in eff.stat_delta:
		m = maxi(m, absi(int(eff.stat_delta[k])))
	for civ in eff.rapporti_civilta:
		m = maxi(m, absi(int(eff.rapporti_civilta[civ])))
	m = maxi(m, absi(int(eff.popolazione_delta)))
	return clampf(0.85 + float(m) / 22.0, 0.85, 1.6)


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


# Riempie la barra 0–100 della stat e la colora dal bronzo (debole) all'oro (forte).
func _aggiorna_barra_stat(nome: String, valore: int) -> void:
	var fill: ColorRect = stat_bar_fills.get(nome)
	if fill == null or not is_instance_valid(fill):
		return
	var frac: float = clampf(float(valore) / float(GameState.STAT_MAX), 0.0, 1.0)
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_bottom = 1.0
	fill.anchor_right = frac
	fill.offset_left = 0.0
	fill.offset_top = 0.0
	fill.offset_right = 0.0
	fill.offset_bottom = 0.0
	fill.color = Color(0.52, 0.40, 0.24).lerp(Color(0.98, 0.82, 0.46), frac)


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
			var iv: int = int(round(value))
			if is_instance_valid(label):
				label.text = str(iv)
			_aggiorna_barra_stat(nome, iv),
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
	if is_instance_valid(village) and (nome == "popolo" or nome == "tesoro"):
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


# J13: lampo bianco brevissimo su tutta la scena al momento del drop. Overlay autonomo
# (si auto-libera), mouse-ignore, sopra l'UI ma sotto pausa/Ledger.
func _flash_drop() -> void:
	var f: ColorRect = ColorRect.new()
	f.color = Color(1, 1, 1, 0.45)
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(f)
	var t: Tween = create_tween()
	t.tween_property(f, "color:a", 0.0, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(f.queue_free)


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
		# Glifo di stato (▲ alleato / ▼ ostile / • neutro) oltre al colore del bordo.
		var glifo: String = "▲" if valore > 0 else ("▼" if valore < 0 else "•")
		lbl.text = "%s %s\n%s%d" % [glifo, nome, segno, valore]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var col_val: Color = Color(0.6, 1.0, 0.6) if valore > 0 else (Color(1.0, 0.6, 0.6) if valore < 0 else Color(1, 1, 1, 0.8))
		lbl.add_theme_color_override("font_color", col_val)
		row.add_child(lbl)
		# Badge bronzo invece di riga nuda: tinta del bordo = stato del rapporto.
		var badge: PanelContainer = PanelContainer.new()
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		var tint: Color = Color(0.6, 0.95, 0.6) if valore > 0 else (Color(0.95, 0.55, 0.5) if valore < 0 else Color(0.62, 0.46, 0.27))
		sb.bg_color = Color(0.12, 0.09, 0.07, 0.85)
		sb.border_color = Color(tint.r, tint.g, tint.b, 0.7)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 5
		sb.content_margin_bottom = 5
		badge.add_theme_stylebox_override("panel", sb)
		badge.add_child(row)
		# J8: ingresso a cascata; flash colorato se il rapporto è appena cambiato.
		var idx: int = rapporti_box.get_child_count()
		var cambiato: bool = not _rapporti_prec.is_empty() \
			and _rapporti_prec.has(civ_id) and int(_rapporti_prec[civ_id]) != valore
		badge.modulate = Color(1, 1, 1, 0)
		rapporti_box.add_child(badge)
		var tw: Tween = create_tween()
		tw.tween_interval(0.04 * idx)
		tw.tween_property(badge, "modulate:a", 1.0, 0.22)
		if cambiato:
			var su: bool = valore > int(_rapporti_prec[civ_id])
			var pop: Color = Color(1.5, 1.5, 1.5) if su else Color(1.6, 1.15, 1.1)
			tw.tween_property(badge, "modulate", pop, 0.12)
			tw.tween_property(badge, "modulate", Color.WHITE, 0.55)
	rapporti_label.text = "Rapporti:" if qualcuno else ""
	_rapporti_prec = GameState.rapporti_civilta.duplicate()
	_refresh_bandiere_alleati()


# J15 — Pianta uno stendardo sul villaggio per ogni civilta' alleata (rapporto >= soglia).
func _refresh_bandiere_alleati() -> void:
	if village == null:
		return
	var ids: Array = []
	for civ_id in GameState.rapporti_civilta.keys():
		if int(GameState.rapporti_civilta[civ_id]) >= SOGLIA_RAPPORTO:
			ids.append(civ_id)
	village.mostra_bandiere_alleati(ids)


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
		KEY_V: _toggle_villaggio()
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
		KEY_B: _avvia_assedio(GameState.era_corrente)   # prova L'Assedio al volo
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
		AudioManager.play_sfx("ledger_open")
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

	var thumb_tex: Texture2D = _tex_edificio(era, tipo)
	if thumb_tex != null:
		vb.add_child(_thumb_edificio(thumb_tex))

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
		vb.add_child(_riga_costo(_icona_risorse(), "Costo:",
			"%d Risorse  (hai %d)" % [costo, GameState.risorse], ok_risorse))
		vb.add_child(_riga_costo(_icona_stat_tex("costruzione"), "Costruzione:",
			"≥ %d  (hai %d)" % [gate, GameState.get_stat("costruzione")], ok_gate))
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
	_anima_apertura_pannello()


func _esegui_upgrade(era: int, slot: int, stat: String, costo: int, bonus: int, da_lista: bool = false) -> void:
	if GameState.risorse < costo:
		return
	GameState.modifica_risorse(-costo)
	GameState.modifica_stat(stat, bonus)
	GameState.migliora_edificio(era, slot)
	AudioManager.play_sfx("quest_complete")
	SaveSystem.save_run()
	_refresh_potenziabili()
	_check_traguardi_villaggio()
	_chiudi_pannello_edificio()
	# Dalla vista gestionale: si resta nel pannello (ricaricato coi nuovi valori).
	if da_lista:
		_apri_pannello_villaggio()


# --- Vista villaggio gestionale (doc 10 §4.2) -------------------------------
# Pannello d'insieme: elenco di tutti gli edifici con livello, stat sviluppata e
# Risorse prodotte/turno, con upgrade da un unico posto. Tasto V (o click-out/ESC).

func _toggle_villaggio() -> void:
	if edificio_panel != null and is_instance_valid(edificio_panel):
		_chiudi_pannello_edificio()
		return
	if processing_drop or in_transizione_era:
		return
	if $UI/ConsigliereProposer.visible:
		return
	if ledger_screen_instance != null and is_instance_valid(ledger_screen_instance):
		return
	_apri_pannello_villaggio()


func _apri_pannello_villaggio() -> void:
	if village == null:
		return
	var era: int = GameState.era_corrente
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
	box.offset_left = -300.0
	box.offset_right = 300.0
	box.offset_top = -250.0
	box.offset_bottom = 250.0
	edificio_panel.add_child(box)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	box.add_child(vb)

	vb.add_child(_lbl_titolo("Il Villaggio"))
	var prod: int = _produzione_per_turno()
	vb.add_child(_lbl("Risorse %d    ·    Produzione +%d/turno    ·    Popolazione %d" % [
		GameState.risorse, prod, GameState.popolazione], 15, Color(0.86, 0.80, 0.64)))
	vb.add_child(_separatore_panel())

	if village.slot_count() == 0:
		vb.add_child(_lbl("Nessun edificio ancora.\nTocca il segno + a terra per costruire il primo.",
			16, Color(0.78, 0.72, 0.6)))
	else:
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 300)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vb.add_child(scroll)
		var lista: VBoxContainer = VBoxContainer.new()
		lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lista.add_theme_constant_override("separation", 6)
		scroll.add_child(lista)
		for s in range(village.slot_count()):
			lista.add_child(_riga_edificio(era, s))

	var liberi: int = village.slot_max() - village.slot_count()
	if liberi > 0:
		vb.add_child(_separatore_panel())
		vb.add_child(_lbl("%d lotto/i libero/i — tocca il segno + a terra per costruire." % liberi,
			14, Color(0.74, 0.68, 0.56)))

	var chiudi: Button = Button.new()
	chiudi.text = "Chiudi"
	chiudi.pressed.connect(_chiudi_pannello_edificio)
	vb.add_child(chiudi)

	add_child(edificio_panel)
	_anima_apertura_pannello()


# Una riga della vista gestionale: icona stat + nome/stelle + dettaglio produzione,
# e un pulsante Migliora (o "Max") allineato a destra.
func _riga_edificio(era: int, slot: int) -> Control:
	var tipo: int = village.tipo_at(slot)
	var nome: String = EDIFICIO_NOME_ERA.get(era, {}).get(tipo, "Edificio")
	var stat: String = EDIFICIO_STAT_ERA.get(era, {}).get(tipo, "popolo")
	var lv: int = GameState.livello_edificio(era, slot)
	var eco: bool = bool(EDIFICIO_ECONOMICO.get(era, {}).get(tipo, false))
	var contributo: int = lv * (2 if eco else 1)

	var riga: PanelContainer = PanelContainer.new()
	riga.add_theme_stylebox_override("panel", UiStyle.chip_stylebox())
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	riga.add_child(hb)

	var ic: TextureRect = TextureRect.new()
	ic.custom_minimum_size = Vector2(30, 30)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ict: Texture2D = _icona_stat_tex(stat)
	if ict != null:
		ic.texture = ict
	hb.add_child(ic)

	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 1)
	hb.add_child(col)
	var titolo: Label = Label.new()
	titolo.text = nome + ("  " + "★".repeat(lv - 1) if lv > 1 else "")
	titolo.add_theme_font_size_override("font_size", 18)
	titolo.add_theme_color_override("font_color", Color(0.95, 0.88, 0.66))
	col.add_child(titolo)
	var sub: Label = Label.new()
	sub.text = "Sviluppa %s  ·  +%d Risorse/turno%s" % [
		STAT_LABELS.get(stat, stat), contributo, "  ·  Risorse ×2" if eco else ""]
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.78, 0.72, 0.6))
	col.add_child(sub)

	if lv >= GameState.EDIFICIO_LIVELLO_MAX:
		var maxl: Label = Label.new()
		maxl.text = "Max"
		maxl.add_theme_font_size_override("font_size", 15)
		maxl.add_theme_color_override("font_color", Color(0.7, 0.66, 0.55))
		maxl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(maxl)
	else:
		var nx: int = lv + 1
		var costo: int = int(UPGRADE_COSTO[nx])
		var gate: int = int(UPGRADE_GATE_COSTR[nx])
		var bonus: int = int(UPGRADE_BONUS[nx])
		var ok: bool = GameState.risorse >= costo and GameState.get_stat("costruzione") >= gate
		var b: Button = Button.new()
		b.text = "Migliora (%d)" % costo
		b.disabled = not ok
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.tooltip_text = "Livello %d → %d:  +%d %s\nCosto %d Risorse · Costruzione ≥ %d (hai %d)" % [
			lv, nx, bonus, STAT_LABELS.get(stat, stat), costo, gate, GameState.get_stat("costruzione")]
		var era_c: int = era
		var slot_c: int = slot
		var stat_c: String = stat
		var costo_c: int = costo
		var bonus_c: int = bonus
		b.pressed.connect(func() -> void:
			_esegui_upgrade(era_c, slot_c, stat_c, costo_c, bonus_c, true))
		hb.add_child(b)
	return riga


func _icona_stat_tex(stat: String) -> Texture2D:
	var p: String = STAT_ICON_DIR + stat + ".png"
	return load(p) if ResourceLoader.exists(p) else null


# Sprite base dell'edificio (per le thumbnail nei modali build/upgrade).
func _tex_edificio(era: int, tipo: int) -> Texture2D:
	var p: String = "res://Assets/art/villaggio/era%d/%02d.png" % [era, tipo]
	return load(p) if ResourceLoader.exists(p) else null


# Icona della valuta "Risorse": dedicata se esiste, altrimenti proxy Costruzione.
func _icona_risorse() -> Texture2D:
	var p: String = "res://Assets/art/icons/risorse.png"
	if ResourceLoader.exists(p):
		return load(p)
	return _icona_stat_tex("costruzione")


# Thumbnail centrata dell'edificio per la testa dei modali.
func _thumb_edificio(tex: Texture2D) -> TextureRect:
	var thumb: TextureRect = TextureRect.new()
	thumb.texture = tex
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.custom_minimum_size = Vector2(0, 92)
	thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return thumb


# Riga di costo allineata: icona + "Etichetta valore", verde se soddisfatto.
func _riga_costo(icon: Texture2D, etichetta: String, valore: String, ok: bool) -> HBoxContainer:
	var hb: HBoxContainer = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	if icon != null:
		var ic: TextureRect = TextureRect.new()
		ic.texture = icon
		ic.custom_minimum_size = Vector2(24, 24)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
	var l: Label = Label.new()
	# Glifo ✓/✗ oltre al colore: leggibile anche con daltonismo (accessibilità).
	l.text = "%s  %s  %s" % ["✓" if ok else "✗", etichetta, valore]
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.62, 0.95, 0.62) if ok else Color(1.0, 0.6, 0.55))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	return hb


func _anima_apertura_pannello() -> void:
	# Fade-in morbido del pannello modale (dim + box) invece dell'apparizione di scatto.
	if edificio_panel == null or not is_instance_valid(edificio_panel):
		return
	var t: Tween = create_tween()
	t.set_parallel()
	for c in edificio_panel.get_children():
		if c is CanvasItem:
			(c as CanvasItem).modulate.a = 0.0
			t.tween_property(c, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)


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


# Traguardi del villaggio (progressione stile Clash/Lapse): costruire e migliorare
# sblocca ricompense una volta per run, con un toast celebrativo. I flag persistono
# nel save e si azzerano al reset.
func _check_traguardi_villaggio() -> void:
	if village == null:
		return
	var era: int = GameState.era_corrente
	var n: int = village.slot_count()
	var ha_lv_max: bool = false
	for s in range(n):
		if GameState.livello_edificio(era, s) >= GameState.EDIFICIO_LIVELLO_MAX:
			ha_lv_max = true
			break
	if n >= 3 and not GameState.has_flag("trg_borgo"):
		GameState.set_flag("trg_borgo", true)
		GameState.modifica_risorse(12)
		_toast_traguardo("Il Borgo Cresce", "+12 Risorse")
	if n >= village.slot_max() and not GameState.has_flag("trg_completo"):
		GameState.set_flag("trg_completo", true)
		GameState.modifica_risorse(20)
		GameState.modifica_stat("costruzione", 3)
		_toast_traguardo("Villaggio Compiuto", "+20 Risorse  ·  +3 Costruzione")
	if ha_lv_max and not GameState.has_flag("trg_maestria"):
		GameState.set_flag("trg_maestria", true)
		GameState.modifica_risorse(15)
		GameState.modifica_stat("popolo", 3)
		_toast_traguardo("Opera Maestra", "+15 Risorse  ·  +3 Popolo")


func _toast_traguardo(titolo: String, premio: String) -> void:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", _stile_pannello())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.offset_left = -300.0
	p.offset_right = 300.0
	p.offset_top = 92.0
	p.offset_bottom = 172.0
	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	var t1: Label = Label.new()
	t1.text = "Traguardo:  %s" % titolo
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 24)
	t1.add_theme_color_override("font_color", Color(0.95, 0.84, 0.5))
	var f: Font = _font_titoli()
	if f != null:
		t1.add_theme_font_override("font", f)
	vb.add_child(t1)
	var t2: Label = Label.new()
	t2.text = premio
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 16)
	t2.add_theme_color_override("font_color", Color(0.66, 0.95, 0.66))
	vb.add_child(t2)
	$UI.add_child(p)
	p.modulate.a = 0.0
	AudioManager.play_sfx("ledger_unlock")
	var t: Tween = create_tween()
	t.tween_property(p, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	t.tween_interval(2.6)
	t.tween_property(p, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(p.queue_free)


# Posta in gioco: una sciagura (forte calo di popolazione) abbatte di un livello un
# edificio già migliorato. Mai sotto il livello 1 e mai su un villaggio "giovane":
# è un contraccolpo da ricostruire, non una punizione che azzera i progressi.
func _check_danno_catastrofe(eff: Effect) -> String:
	if eff == null or village == null:
		return ""
	if eff.popolazione_delta > -4:
		return ""
	var era: int = GameState.era_corrente
	var candidati: Array = []
	for s in range(village.slot_count()):
		if GameState.livello_edificio(era, s) > 1:
			candidati.append(s)
	if candidati.is_empty():
		return ""
	var slot: int = candidati[randi() % candidati.size()]
	var tipo: int = village.tipo_at(slot)
	var nome: String = EDIFICIO_NOME_ERA.get(era, {}).get(tipo, "Un edificio")
	GameState.danneggia_edificio(era, slot)
	village.danneggia(slot)
	_refresh_potenziabili()
	AudioManager.play_sfx("stat_down")
	return "\n\nLa sciagura colpisce il villaggio: %s crolla di un livello." % nome


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
	# Barra compatta che si adatta al contenuto e resta centrata in alto (niente cornice
	# ornata stirata: quella su una striscia larga e sottile fa pessima figura).
	bar.add_theme_stylebox_override("panel", UiStyle.panel_clean())
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.offset_top = 12.0
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
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


func _apri_pannello_costruzione(_slot: int) -> void:
	# Vera agency da builder: il giocatore SCEGLIE quale edificio erigere sul lotto
	# (puoi specializzare il villaggio — militare, economico, sapere...).
	var era: int = GameState.era_corrente
	var nomi: Dictionary = EDIFICIO_NOME_ERA.get(era, {})
	if nomi.is_empty():
		return
	var ok_risorse: bool = GameState.risorse >= BUILD_COSTO
	var ok_gate: bool = GameState.get_stat("costruzione") >= BUILD_GATE_COSTR
	var ok: bool = ok_risorse and ok_gate
	var vb: VBoxContainer = _nuovo_pannello_modale()
	vb.add_child(_lbl_titolo("Cosa costruire?"))
	vb.add_child(_riga_costo(_icona_risorse(), "Costo:",
		"%d Risorse (hai %d)  ·  Costruzione ≥ %d (hai %d)" % [
		BUILD_COSTO, GameState.risorse, BUILD_GATE_COSTR, GameState.get_stat("costruzione")], ok))
	vb.add_child(_separatore_panel())
	var tipi: Array = nomi.keys()
	tipi.sort()
	for tipo in tipi:
		var nome: String = nomi[tipo]
		var stat: String = EDIFICIO_STAT_ERA.get(era, {}).get(tipo, "popolo")
		var eco: bool = bool(EDIFICIO_ECONOMICO.get(era, {}).get(tipo, false))
		var extra: String = "  ·  Risorse ×2" if eco else ""
		var b: Button = Button.new()
		b.text = "%s   +%d %s%s" % [nome, BUILD_BONUS, STAT_LABELS.get(stat, stat), extra]
		b.disabled = not ok
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var bt: Texture2D = _tex_edificio(era, int(tipo))
		if bt != null:
			b.icon = bt
			b.add_theme_constant_override("icon_max_width", 38)
		var tipo_c: int = int(tipo)
		var stat_c: String = stat
		b.pressed.connect(func() -> void: _esegui_build(tipo_c, stat_c))
		vb.add_child(b)
	var chiudi: Button = Button.new()
	chiudi.text = "Chiudi"
	chiudi.pressed.connect(_chiudi_pannello_edificio)
	vb.add_child(chiudi)
	add_child(edificio_panel)
	_anima_apertura_pannello()


func _esegui_build(tipo: int, stat: String) -> void:
	if GameState.risorse < BUILD_COSTO:
		return
	if village.slot_count() >= village.slot_max():
		return
	GameState.modifica_risorse(-BUILD_COSTO)
	if stat != "":
		GameState.modifica_stat(stat, BUILD_BONUS)
	village.costruisci(tipo)
	GameState.set_flag("villaggio_n", village.slot_count())
	AudioManager.play_sfx("quest_complete")
	SaveSystem.save_run()
	_refresh_potenziabili()
	_check_traguardi_villaggio()
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
	box.offset_left = -265.0
	box.offset_right = 265.0
	box.offset_top = -275.0
	box.offset_bottom = 275.0
	edificio_panel.add_child(box)
	var vb: VBoxContainer = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 9)
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
	_ferma_idle_decisione()
	_rapporti_prec.clear()   # J8: nuova run, niente flash da valori vecchi
	_show_narrative("")
	in_transizione_era = false
	if siege_instance != null and is_instance_valid(siege_instance):
		siege_instance.queue_free()
		siege_instance = null
	if ending_instance != null and is_instance_valid(ending_instance):
		ending_instance.queue_free()
		ending_instance = null
	var bg: ColorRect = $UI/Background
	if bg != null:
		bg.color = COLOR_BG_ERA1
	_refresh_rapporti()
	_refresh_effetti_duraturi()
	_start_era1()
