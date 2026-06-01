extends Node

const MAX_HISTORY: int = 50

var coda: Array[String] = []
var storia: Array[String] = []

signal new_entry(testo: String)


func append(testo: String) -> void:
	if testo.is_empty():
		return
	coda.append(testo)
	storia.append(testo)
	if storia.size() > MAX_HISTORY:
		storia.pop_front()
	new_entry.emit(testo)


func consuma_prossimo() -> String:
	if coda.is_empty():
		return ""
	return coda.pop_front()


func has_pending() -> bool:
	return not coda.is_empty()


func reset() -> void:
	coda.clear()
	storia.clear()
