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
	"lore_marcia_impero": {
		"titolo": "La Marcia contro l'Impero",
		"testo": "Le legioni mossero verso est. Il cielo del Sole calante si tinse di fumo: il regno scelse la spada."
	},
	"lore_pace_imperi": {
		"titolo": "La Pace tra gli Imperi",
		"testo": "Sereth cucì un patto impossibile tra il Sole e le Coste. Il regno divenne il centro indispensabile di molti."
	},
	"lore_grande_fonderia": {
		"titolo": "La Grande Fonderia",
		"testo": "Fumo e ingranaggi anticiparono un'era non ancora nata. Il regno costruì oltre il sognabile, e consumò oltre il restituibile."
	},
	"lore_convergenza": {
		"titolo": "La Convergenza",
		"testo": "La presenza dei sogni entrò nel popolo attraverso il tempio. Il volto senza nome ebbe finalmente un nome: noi."
	},
	"lore_voce_rifiutata": {
		"titolo": "La Voce Rifiutata",
		"testo": "Il popolo chiuse il tempio e le sue domande. Restammo umani: fragili, mortali, liberi. La Voce tacque."
	},
	"lore_scelta_finale": {
		"titolo": "La Scelta Finale",
		"testo": "L'ultima decisione dello spirito. Ogni era confluisce qui, e il Ledger registra ciò che siamo diventati."
	},
	"lore_peste": {
		"titolo": "La Peste",
		"testo": "Il morbo salì dalla porta del fiume e raddoppiò ogni quattro giorni. Il regno imparò a combattere un nemico senza bandiera."
	},
	"lore_ribellione": {
		"titolo": "La Rivolta delle Fornaci",
		"testo": "Il quartiere delle fornaci bruciò i registri delle tasse e alzò barricate. Dietro ogni barricata, volti che il regno conosceva per nome."
	},
	"lore_lama_buio": {
		"titolo": "La Lama nel Buio",
		"testo": "Una lama fermata a tre passi dal consiglio, una moneta straniera cucita in un mantello. Qualcuno voleva il trono vuoto prima della grande scelta."
	},
	"lore_carestia_razioni": {
		"titolo": "I Granai Contati",
		"testo": "Quando la pioggia non venne, Vorrik divise il regno in bocche e misure. Si sopravvisse a peso e registro: il pane bastò, e nessuno dimenticò la mano magra del Cancelliere."
	},
	"lore_carestia_lega": {
		"titolo": "Il Pane Straniero",
		"testo": "Nell'anno secco le stive della Lega salvarono il regno, e l'oro partì con la marea. Si imparò che la fame ha un prezzo, e che chi vende il pane decide chi mangia."
	},
	"lore_carestia_canali": {
		"titolo": "I Canali di Lena",
		"testo": "Contro la siccità Lena non pregò la pioggia: scavò per raggiungerla. I canali rimasero anche dopo la fame, e la terra arsa imparò a bere dal fiume."
	},
	"epilogo_fine_guerra": {"titolo": "Epilogo: Era della Guerra", "testo": "Lo spirito scelse la spada e vinse, al prezzo del fumo e delle tombe."},
	"epilogo_fine_prosperita": {"titolo": "Epilogo: Era della Prosperità", "testo": "Lo spirito scelse il pane e il commercio. Un'era morbida, di lunghe estati."},
	"epilogo_fine_scienza": {"titolo": "Epilogo: Era della Scienza", "testo": "Lo spirito protesse il sapere e aprì porte che nessuno sapeva chiuse."},
	"epilogo_fine_alleanza": {"titolo": "Epilogo: Era dell'Alleanza", "testo": "Lo spirito non scelse un solo padrone e divenne indispensabile a tutti."},
	"epilogo_fine_industria": {"titolo": "Epilogo: Era dell'Industria", "testo": "Lo spirito accese la fonderia: progresso e perdita, mano nella mano."},
	"epilogo_fine_futura": {"titolo": "Epilogo: Era Futura", "testo": "Lo spirito accolse la Voce e attraversò la soglia oltre l'umano."},
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
	_setup_contatori()
	_populate_lore()
	_populate_artefatti()
	_populate_eventi()


# Il progresso meta a colpo d'occhio (alla Lapse): quanto resta da scoprire.
func _setup_contatori() -> void:
	var epiloghi_visti: int = 0
	for id in Ledger.lore_sbloccata:
		if String(id).begins_with("epilogo_"):
			epiloghi_visti += 1
	var tot_artefatti: int = 0
	var dir: DirAccess = DirAccess.open(ARTEFATTI_DIR)
	if dir != null:
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.ends_with(".tres"):
				tot_artefatti += 1
			fname = dir.get_next()
		dir.list_dir_end()
	var lbl: Label = Label.new()
	lbl.text = "Epiloghi vissuti: %d / 6      Artefatti: %d / %d" % [
		epiloghi_visti, Ledger.artefatti_sbloccati.size(), tot_artefatti]
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.65, 0.42))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vbox: VBoxContainer = $Panel/Margin/VBox
	vbox.add_child(lbl)
	vbox.move_child(lbl, 2)


func _populate_lore() -> void:
	for c in lore_list.get_children():
		c.queue_free()
	if Ledger.lore_sbloccata.is_empty():
		# Il vuoto e' un mistero da scoprire, non un errore.
		var empty: Label = Label.new()
		empty.text = "Nessuna lore ancora scoperta.\n\nLe scelte ricche di significato lasciano segno qui."
		empty.add_theme_font_size_override("font_size", 14)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.modulate = Color(0.78, 0.66, 0.45, 0.8)
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
	var unlocked: bool = Ledger.is_artefatto_unlocked(art.id)
	var scelto: bool = Ledger.artefatto_scelto == art.id
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 360)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	if unlocked:
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(200, 200)
		icon.texture = art.icona
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon)
	else:
		# Stato bloccato "disegnato" (audit #10): medaglione bronzo + silhouette + "?".
		var med: Panel = Panel.new()
		med.custom_minimum_size = Vector2(200, 200)
		var msb: StyleBoxFlat = StyleBoxFlat.new()
		msb.bg_color = Color(0.12, 0.10, 0.08, 0.92)
		msb.border_color = Color(0.5, 0.38, 0.24, 0.9)
		msb.set_border_width_all(3)
		msb.set_corner_radius_all(100)
		msb.shadow_color = Color(0, 0, 0, 0.4)
		msb.shadow_size = 6
		med.add_theme_stylebox_override("panel", msb)
		var sil: TextureRect = TextureRect.new()
		sil.set_anchors_preset(Control.PRESET_FULL_RECT)
		sil.texture = art.icona
		sil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sil.modulate = Color(0.30, 0.25, 0.20, 0.85)
		med.add_child(sil)
		var q: Label = Label.new()
		q.set_anchors_preset(Control.PRESET_FULL_RECT)
		q.text = "?"
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 70)
		q.add_theme_color_override("font_color", Color(0.72, 0.6, 0.38, 0.9))
		med.add_child(q)
		vbox.add_child(med)
	var nome_lbl: Label = Label.new()
	nome_lbl.text = art.nome if unlocked else "???"
	nome_lbl.add_theme_font_size_override("font_size", 16)
	nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not unlocked:
		nome_lbl.add_theme_color_override("font_color", Color(0.72, 0.6, 0.4))
	vbox.add_child(nome_lbl)
	var desc_lbl: Label = Label.new()
	if unlocked:
		desc_lbl.text = art.descrizione
	elif art.sblocco_hint != "":
		desc_lbl.text = art.sblocco_hint
	else:
		desc_lbl.text = "Un artefatto ancora da conquistare."
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.modulate = Color(1, 1, 1, 0.7 if unlocked else 0.5)
	vbox.add_child(desc_lbl)
	if scelto:
		var equipped_lbl: Label = Label.new()
		if GameState.artefatto_equipaggiato == art.id:
			equipped_lbl.text = "EQUIPAGGIATO"
		else:
			equipped_lbl.text = "EQUIPAGGIATO\n(dalla prossima run)"
		equipped_lbl.add_theme_font_size_override("font_size", 12)
		equipped_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipped_lbl.modulate = Color(1.0, 0.85, 0.4)
		vbox.add_child(equipped_lbl)
		card.modulate = Color(1.15, 1.15, 0.85)
	if unlocked:
		card.tooltip_text = "Clicca per rimuovere" if scelto else "Clicca per equipaggiare"
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(_on_artefatto_card_input.bind(art.id))
	return card


func _on_artefatto_card_input(event: InputEvent, art_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Ledger.scegli_artefatto(art_id)
		_populate_artefatti()


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
			lbl.modulate = Color(0.78, 0.66, 0.45, 0.55)
		eventi_list.add_child(lbl)


func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()
