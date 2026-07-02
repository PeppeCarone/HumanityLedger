extends Node

# Playtest del DUELLO FINALE "L'Ultimo Dio" (Docs/20): gioca il duello (era 2, finale=true)
# con un GIOCATORE ATTIVO (evoca/potenzia spendendo le monete del drip) e diverse dotazioni
# di ARSENALE del villaggio (nessuno / medio / pieno), per tarare HP del Dio / drip / armatura.
# Esegui: godot --headless --path . tools/playtest_finale.tscn
# Obiettivo balance: senza arsenale → duro (fatica/sopraffatto); arsenale pieno → trionfo con
# tensione (villaggio intaccato, non immacolato); l'investimento nel villaggio deve CONTARE.

const BUILDS := [
	{"nome": "DEBOLE", "mil": 34, "cos": 34, "sci": 30, "spi": 26, "leg": 30, "tes": 34, "ris": 30, "pop": 38},
	{"nome": "MEDIO",  "mil": 46, "cos": 44, "sci": 40, "spi": 34, "leg": 38, "tes": 42, "ris": 40, "pop": 46},
	{"nome": "FORTE",  "mil": 58, "cos": 55, "sci": 50, "spi": 46, "leg": 46, "tes": 50, "ris": 48, "pop": 54},
]
# Dotazioni d'arsenale (dal villaggio): quello che l'edificio-loadout concede al duello.
const ARSENALI := [
	{"nome": "no-ars", "a": {}},
	{"nome": "medio",  "a": {"hp": 42, "monete": 10, "truppe": 1, "livello": 2}},
	{"nome": "PIENO",  "a": {"hp": 84, "monete": 30, "truppe": 1, "livello": 2}},
]
const ROTAZIONE := ["bloccatore", "tiratore", "bloccatore", "totem", "tiratore", "bloccatore", "sciamano", "tiratore", "bloccatore"]


func _ready() -> void:
	# QA isolata dallo STATO UTENTE persistente (NG+/difficoltà): solo in memoria.
	Ledger.eone = 0
	AudioManager._difficolta = 1
	Engine.time_scale = 8.0
	print("===== DUELLO FINALE — L'ULTIMO DIO =====")
	await _run(BUILDS[2], ARSENALI[2])   # FORTE + arsenale PIENO  (giocatore investito)
	await _run(BUILDS[2], ARSENALI[0])   # FORTE + nessun arsenale  (stat forti, villaggio spoglio)
	await _run(BUILDS[1], ARSENALI[2])   # MEDIO + arsenale PIENO
	await _run(BUILDS[0], ARSENALI[2])   # DEBOLE + arsenale PIENO
	Engine.time_scale = 1.0
	print("FINALE_DONE")
	get_tree().quit()


func _run(cfg: Dictionary, ars: Dictionary) -> void:
	Engine.time_scale = 8.0   # ripristino: un hitstop residuo del run precedente lascerebbe lo scale basso
	GameState.reset_run()
	GameState.era_corrente = 2
	GameState.militare = cfg["mil"]; GameState.costruzione = cfg["cos"]
	GameState.scienza = cfg["sci"]; GameState.spionaggio = cfg["spi"]; GameState.legge = cfg["leg"]
	GameState.tesoro = cfg["tes"]; GameState.risorse = cfg["ris"]; GameState.popolo = cfg["pop"]
	var siege: Node = SiegeArena.new()
	siege.finale = true
	siege.configura(2)
	siege.applica_arsenale(ars["a"])
	get_tree().root.add_child.call_deferred(siege)
	await get_tree().process_frame
	await get_tree().process_frame
	var frames: int = 0
	var summon_t: float = 0.0
	var ri: int = 0
	var max_fase: int = 1
	while not siege._concluso and frames < 7000:
		await get_tree().process_frame
		frames += 1
		if siege._boss != null and is_instance_valid(siege._boss):
			max_fase = maxi(max_fase, int(siege._boss._fase))
		if frames % 1500 == 0:
			var bhp: int = int(siege._boss.hp) if (siege._boss != null and is_instance_valid(siege._boss)) else -1
			print("   ...f=%d villaggio=%d fase=%d boss_hp=%d monete=%d" % [frames, siege.hp_villaggio, max_fase, bhp, siege.risorse])
		summon_t += get_process_delta_time()
		if summon_t >= 1.3:
			summon_t = 0.0
			siege._evoca(str(ROTAZIONE[ri % ROTAZIONE.size()]))
			ri += 1
			if ri % 4 == 0 and siege.risorse > 60:
				siege._potenzia("tiratore")
			elif ri % 6 == 0 and siege.risorse > 80:
				siege._potenzia("bloccatore")
	var pct: int = int(100.0 * float(siege.hp_villaggio) / float(maxi(siege.hp_villaggio_max, 1)))
	var esito: String = "TIMEOUT"
	if siege._concluso:
		if siege.hp_villaggio <= 0: esito = "sopraffatto"
		elif pct >= 100: esito = "immacolata"
		elif pct >= 40: esito = "trionfo"
		else: esito = "fatica"
	print("FINALE  %-7s  ars=%-6s -> %-12s  villaggio=%3d%%  (fase_max=%d hp_max=%d monete_res=%d)" % [
		str(cfg["nome"]), str(ars["nome"]), esito, pct, max_fase, siege.hp_villaggio_max, siege.risorse])
	siege.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
