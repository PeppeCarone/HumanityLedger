extends Node

# Playtest della CURVA di difficoltà dell'Assedio (Fase F5): gioca lo stesso Assedio con 3
# build (debole/medio/forte) simulando un GIOCATORE ATTIVO che evoca/potenzia a cadenza
# spendendo le monete — così misura il vero loop, non un esercito statico (che perde sempre).
# Esegui: godot --headless --path . tools/playtest_curve.tscn
# Atteso (balance 2026-06-23): tutte le build VINCONO con QUALCHE danno (trionfo ~85-100%),
# finendo quasi senza monete; un giocatore PASSIVO invece viene sopraffatto (vedi playtest_assedio).

const BUILDS := [
	{"nome": "DEBOLE", "mil": 28, "cos": 28, "sci": 24, "spi": 20, "leg": 22, "tes": 30, "ris": 28, "pop": 32},
	{"nome": "MEDIO", "mil": 40, "cos": 38, "sci": 34, "spi": 30, "leg": 32, "tes": 40, "ris": 36, "pop": 42},
	{"nome": "FORTE", "mil": 55, "cos": 52, "sci": 45, "spi": 42, "leg": 45, "tes": 48, "ris": 42, "pop": 50},
]
# Ordine di evocazione del "giocatore attivo" (favorisce la linea di bloccatori, poi supporto).
const ROTAZIONE := ["bloccatore", "bloccatore", "tiratore", "bloccatore", "totem", "tiratore", "bloccatore", "sciamano", "tiratore"]


func _ready() -> void:
	Engine.time_scale = 8.0
	for era in [1, 2]:
		print("===== ERA %d =====" % era)
		for cfg in BUILDS:
			await _run_build(cfg, era)
	Engine.time_scale = 1.0
	print("CURVA_DONE")
	get_tree().quit()


func _run_build(cfg: Dictionary, era_n: int = 1) -> void:
	GameState.reset_run()
	GameState.era_corrente = era_n
	GameState.militare = cfg["mil"]; GameState.costruzione = cfg["cos"]
	GameState.scienza = cfg["sci"]; GameState.spionaggio = cfg["spi"]; GameState.legge = cfg["leg"]
	GameState.tesoro = cfg["tes"]; GameState.risorse = cfg["ris"]; GameState.popolo = cfg["pop"]
	var siege: Node = SiegeArena.new()
	siege.configura(era_n)
	get_tree().root.add_child.call_deferred(siege)
	await get_tree().process_frame
	await get_tree().process_frame
	# Giocatore ATTIVO: evoca a cadenza spendendo le monete (e ogni tanto potenzia). Così il
	# test riflette il vero loop (devi continuare a evocare/potenziare), non un esercito statico.
	var frames: int = 0
	var summon_t: float = 0.0
	var ri: int = 0
	while not siege._concluso and frames < 14000:   # boss multi-fase = fight piu lunghi
		await get_tree().process_frame
		frames += 1
		summon_t += get_process_delta_time()
		if summon_t >= 1.5:
			summon_t = 0.0
			siege._evoca(str(ROTAZIONE[ri % ROTAZIONE.size()]))   # costa monete; no-op se non può
			ri += 1
			if ri % 5 == 0 and siege.risorse > 70:
				siege._potenzia("tiratore")
			elif ri % 7 == 0 and siege.risorse > 90:
				siege._potenzia("bloccatore")
	var pct: int = int(100.0 * float(siege.hp_villaggio) / float(maxi(siege.hp_villaggio_max, 1)))
	var esito: String = "TIMEOUT"
	if siege._concluso:
		if siege.hp_villaggio <= 0: esito = "sopraffatto"
		elif pct >= 100: esito = "immacolata"
		elif pct >= 40: esito = "trionfo"
		else: esito = "fatica"
	print("CURVA %-7s -> %-12s villaggio=%d%%  (hp_max=%d budget_residuo=%d)" % [
		str(cfg["nome"]), esito, pct, siege.hp_villaggio_max, siege.risorse])
	siege.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
