extends CanvasLayer

const ARTEFATTI_DIR: String = "res://data/artefatti/"

const LORE_REGISTRY: Dictionary = {
	"lore_sogno_condiviso": {
		"titolo": "Il Sogno Condiviso",
		"testo": "Tre cose ho visto: la pietra, la pioggia, il volto senza nome."
	},
	"lore_uscita_caverna": {
		"titolo": "L'Uscita dalla Caverna",
		"testo": "Il primo passo fuori è anche il primo passo dentro qualcosa di nuovo."
	},
	"lore_fiume_rosso": {
		"titolo": "Il Fiume Rosso",
		"testo": "Per una notte le acque hanno avuto il colore di una decisione."
	},
	"lore_popolo_nebbie": {
		"titolo": "Il Popolo delle Nebbie",
		"testo": "Vengono dal bosco senza alzare la lancia. Parlano con ossa intagliate e canti bassi."
	},
	"lore_segni_nebbie": {
		"titolo": "I Segni delle Nebbie",
		"testo": "I gesti degli stranieri ripetono il sogno di Lyssa. Qualcosa li ha già visti prima di noi."
	},
	"lore_grande_freddo": {
		"titolo": "Il Grande Freddo",
		"testo": "Sette notti senza sole. La caverna ha contato chi resta e chi manca attorno al fuoco."
	},
	"lore_sentiero_fiume": {
		"titolo": "Il Sentiero del Fiume",
		"testo": "Dove scorre l'acqua scorrono anche gli altri popoli. Il clan sceglie la voce."
	},
	"lore_sentiero_monti": {
		"titolo": "Il Sentiero dei Monti",
		"testo": "Sulla roccia alta nessuno sorprende alle spalle. Il clan sceglie la lancia."
	},
	"lore_sentiero_pianura": {
		"titolo": "Il Sentiero della Pianura",
		"testo": "Sulla terra larga si può costruire qualcosa che resti. Il clan sceglie la pietra."
	},
	"lore_accampamento": {
		"titolo": "Il Primo Accampamento",
		"testo": "Un fuoco, un magazzino, un muro. Il popolo smette di rifugiarsi e comincia ad abitare."
	},
	"lore_clan_bisonte": {
		"titolo": "Il Clan del Bisonte",
		"testo": "Più numerosi, padroni del fiume. Il primo popolo che ci guarda come pari, o come preda."
	},
	"lore_pittura_mutata": {
		"titolo": "La Pittura Mutata",
		"testo": "Una figura dipinta cambia sguardo da sola, di notte. Il volto senza nome non resta sulla parete."
	},
	"lore_idolo_del_fuoco": {
		"titolo": "L'Idolo del Fuoco",
		"testo": "La grande pietra che porta la fiamma. Il primo simbolo eterno del popolo, eretto all'alba di un'era."
	},
	"lore_regno_mitico": {
		"titolo": "Il Regno Mitico",
		"testo": "La collina di pietra, le mura, il tempio. Il popolo della caverna è diventato un regno fuori dal tempo."
	},
	"lore_tempio_centrale": {
		"titolo": "Il Tempio Centrale",
		"testo": "Sull'altare arde lo stesso fuoco della caverna. Nessuno ricorda di averlo acceso, eppure non si è mai spento."
	},
	"lore_voce_nel_bosco": {
		"titolo": "La Voce nel Bosco",
		"testo": "Un inviato straniero ripete le parole del sogno paleolitico: il volto senza nome, la voce sotto la pietra. La presenza ha attraversato le ere."
	},
	"lore_impero_sole": {
		"titolo": "L'Impero del Sole",
		"testo": "Vasto e antico, splendente e marcio. A est il Sole tramonta lentamente, e pretende tributi da chi cresce alla sua ombra."
	},
	"lore_lega_coste": {
		"titolo": "La Lega delle Coste",
		"testo": "Mercanti senza re, fedeli solo al guadagno. A ovest le navi della Lega vendono a tutti e tradiscono chiunque, con un sorriso."
	},
	"lore_conflitto_religioso": {
		"titolo": "Il Conflitto Religioso",
		"testo": "La curia teme il sapere, il popolo lo invoca. Il regno si spacca tra chi vuole bruciare i libri e chi morirebbe per leggerli."
	},
	"lore_tempio_vuoto": {
		"titolo": "Il Tempio Vuoto",
		"testo": "Un tempio identico all'Idolo della caverna, apparso senza mani che lo costruissero. La presenza non chiede di essere capita: solo ricordata."
	},
	"lore_imperi_rivali": {
		"titolo": "Gli Imperi Rivali",
		"testo": "Tra il Sole che cala e le Coste che mercanteggiano, il regno mitico impara il prezzo di esistere accanto ad altri."
	},
}

const EVENTI_REGISTRY: Dictionary = {
	"fiume_rosso": "Il Fiume Rosso",
	"voce_nel_bosco": "La Voce nel Bosco",
	"tempio_vuoto": "Il Tempio Vuoto",
}

@onready var lore_list: VBoxContainer = $Panel/Margin/VBox/SectionsRow/LoreSection/Scroll/LoreList
@onready var artefatti_list: HBoxContainer = $Panel/Margin/VBox/SectionsRow/ArtefattiSection/ArtefattiList
@onready var eventi_list: VBoxContainer = $Panel/Margin/VBox/SectionsRow/EventiSection/Scroll/EventiList
@onready var background: ColorRect = $Background


func _ready() -> void:
	background.gui_input.connect(_on_background_input)
	_populate_lore()
	_populate_artefatti()
	_populate_eventi()


func _populate_lore() -> void:
	for c in lore_list.get_children():
		c.queue_free()
	if Ledger.lore_sbloccata.is_empty():
		var empty: Label = Label.new()
		empty.text = "Nessuna lore ancora scoperta.\n\nLe scelte ricche di significato lasciano segno qui."
		empty.add_theme_font_size_override("font_size", 16)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.modulate = Color(1, 1, 1, 0.6)
		lore_list.add_child(empty)
		return
	for lore_id in Ledger.lore_sbloccata:
		var entry: Dictionary = LORE_REGISTRY.get(lore_id, {"titolo": lore_id, "testo": "(testo non in registro)"})
		var titolo_lbl: Label = Label.new()
		titolo_lbl.text = entry["titolo"]
		titolo_lbl.add_theme_font_size_override("font_size", 18)
		lore_list.add_child(titolo_lbl)
		var testo_lbl: Label = Label.new()
		testo_lbl.text = entry["testo"]
		testo_lbl.add_theme_font_size_override("font_size", 14)
		testo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		testo_lbl.modulate = Color(1, 1, 1, 0.75)
		lore_list.add_child(testo_lbl)
		var spacer: Control = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		lore_list.add_child(spacer)


func _populate_artefatti() -> void:
	for c in artefatti_list.get_children():
		c.queue_free()
	var dir: DirAccess = DirAccess.open(ARTEFATTI_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var artefatto: Artefatto = load(ARTEFATTI_DIR + fname) as Artefatto
			if artefatto != null:
				artefatti_list.add_child(_build_artefatto_card(artefatto))
		fname = dir.get_next()
	dir.list_dir_end()


func _build_artefatto_card(art: Artefatto) -> Control:
	var equipped: bool = GameState.artefatto_equipaggiato == art.id
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 360)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(200, 200)
	icon.texture = art.icona
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)
	var nome_lbl: Label = Label.new()
	nome_lbl.text = art.nome
	nome_lbl.add_theme_font_size_override("font_size", 16)
	nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nome_lbl)
	var desc_lbl: Label = Label.new()
	desc_lbl.text = art.descrizione
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.modulate = Color(1, 1, 1, 0.7)
	vbox.add_child(desc_lbl)
	if equipped:
		var equipped_lbl: Label = Label.new()
		equipped_lbl.text = "EQUIPAGGIATO"
		equipped_lbl.add_theme_font_size_override("font_size", 12)
		equipped_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipped_lbl.modulate = Color(1.0, 0.85, 0.4)
		vbox.add_child(equipped_lbl)
		card.modulate = Color(1.15, 1.15, 0.85)
	return card


func _populate_eventi() -> void:
	for c in eventi_list.get_children():
		c.queue_free()
	for evento_id in EVENTI_REGISTRY.keys():
		var nome: String = EVENTI_REGISTRY[evento_id]
		var sbloccato: bool = Ledger.is_evento_disponibile(evento_id)
		var lbl: Label = Label.new()
		if sbloccato:
			lbl.text = "✓ " + nome
		else:
			lbl.text = "???"
		lbl.add_theme_font_size_override("font_size", 16)
		if not sbloccato:
			lbl.modulate = Color(1, 1, 1, 0.5)
		eventi_list.add_child(lbl)


func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()
