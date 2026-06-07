extends CanvasLayer

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

@onready var background: ColorRect = $Background
@onready var titolo_label: Label = $Center/Panel/Margin/VBox/Titolo
@onready var immagine: TextureRect = $Center/Panel/Margin/VBox/Immagine
@onready var testo_label: Label = $Center/Panel/Margin/VBox/Testo
@onready var footer_label: Label = $Center/Panel/Margin/VBox/Footer


func _ready() -> void:
	if finale == null:
		titolo_label.text = "Nessun finale"
		testo_label.text = "(finale non determinato)"
		return
	var tono: Color = TONI.get(finale.id, Color.WHITE)
	titolo_label.text = finale.nome
	titolo_label.modulate = tono
	var cinzel_path: String = "res://Assets/fonts/Cinzel.ttf"
	if ResourceLoader.exists(cinzel_path):
		var fv: FontVariation = FontVariation.new()
		fv.base_font = load(cinzel_path)
		fv.variation_opentype = {"wght": 700}
		titolo_label.add_theme_font_override("font", fv)
	_imposta_illustrazione()
	testo_label.text = finale.testo
	footer_label.text = "Premi R per ricominciare, L per il Ledger"
	background.color = Color(0.04, 0.03, 0.05, 1.0)
	AudioManager.play_music_id("ending")
	titolo_label.modulate.a = 0.0
	testo_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(titolo_label, "modulate:a", 1.0, 1.0)
	tween.tween_property(testo_label, "modulate:a", 1.0, 1.2)


func _imposta_illustrazione() -> void:
	if finale.illustrazione != null:
		immagine.texture = finale.illustrazione
		return
	var nome: String = finale.id.trim_prefix("fine_")
	var path: String = "res://Assets/art/finali/%s.png" % nome
	if ResourceLoader.exists(path):
		immagine.texture = load(path)
	else:
		immagine.visible = false
