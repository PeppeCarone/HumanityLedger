extends Node

const SAVE_PATH: String = "user://save.json"


func save_run() -> bool:
	var data: Dictionary = GameState.to_dict()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Impossibile scrivere save: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_run() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Impossibile leggere save: %s" % FileAccess.get_open_error())
		return false
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("Save corrotto, ignorato")
		return false
	GameState.from_dict(parsed)
	return true


func exists_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_run() -> void:
	GameState.reset_run()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
