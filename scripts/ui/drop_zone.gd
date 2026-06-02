extends Control

@export var zone_id: String = ""
@export var label_text: String = "Drop here"
@export var bg_color: Color = Color(0.18, 0.16, 0.22, 1.0)
@export var hover_color: Color = Color(0.4, 0.75, 0.4, 0.45)
@export var fail_flash_color: Color = Color(0.85, 0.25, 0.25, 0.45)
@export var accepted_item_ids: Array[String] = []

@onready var bg: ColorRect = $Background
@onready var hover: ColorRect = $HoverHighlight
@onready var lbl: Label = $Label

signal item_dropped(data: Dictionary)

var _is_hovering: bool = false


func _ready() -> void:
	bg.color = bg_color
	hover.color = hover_color
	hover.modulate.a = 0.0
	lbl.text = label_text


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var ok: bool = _accepts(data.get("item_id", ""))
	if ok and not _is_hovering:
		_is_hovering = true
		_animate_hover(true)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	_is_hovering = false
	_animate_hover(false)
	item_dropped.emit(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _is_hovering:
		_is_hovering = false
		_animate_hover(false)


func _accepts(item_id: String) -> bool:
	if accepted_item_ids.is_empty():
		return true
	return item_id in accepted_item_ids


func _animate_hover(active: bool) -> void:
	var target: float = 1.0 if active else 0.0
	var tween: Tween = create_tween()
	tween.tween_property(hover, "modulate:a", target, 0.12)


func flash_fail() -> void:
	var original: Color = hover.color
	hover.color = fail_flash_color
	hover.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(hover, "modulate:a", 0.0, 0.35)
	await tween.finished
	hover.color = original
