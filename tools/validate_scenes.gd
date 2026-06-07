extends SceneTree

const SCENES := [
	"res://scenes/main_menu.tscn",
	"res://scenes/main.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ledger_screen.tscn",
	"res://scenes/ending_screen.tscn",
]


func _initialize() -> void:
	var failures := 0
	for path in SCENES:
		var ps: PackedScene = load(path)
		if ps == null:
			printerr("LOAD FAIL: ", path)
			failures += 1
			continue
		var inst: Node = ps.instantiate()
		if inst == null:
			printerr("INSTANTIATE FAIL: ", path)
			failures += 1
			continue
		root.add_child(inst)
		print("OK: ", path)
		inst.queue_free()
	print("VALIDATE_DONE failures=", failures)
	quit(failures)
