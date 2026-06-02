extends Control

@export var item_id: String = ""
@export var label_text: String = "Item"
@export var icon_color: Color = Color(0.7, 0.55, 0.35, 1.0)
@export var stat_to_modify: String = ""
@export var stat_delta: int = 0
@export var feedback_text: String = ""

@onready var bg: ColorRect = $Background
@onready var lbl: Label = $Label

var _consumed: bool = false


func _ready() -> void:
	bg.color = icon_color
	lbl.text = label_text
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _consumed:
		return null
	var preview: Control = _build_preview()
	set_drag_preview(preview)
	return {
		"item_id": item_id,
		"label": label_text,
		"icon_color": icon_color,
		"stat": stat_to_modify,
		"delta": stat_delta,
		"feedback": feedback_text,
		"source": self,
	}


func _build_preview() -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = size
	var rect: ColorRect = ColorRect.new()
	rect.color = icon_color
	rect.modulate = Color(1, 1, 1, 0.85)
	rect.size = size
	c.add_child(rect)
	var l: Label = Label.new()
	l.text = label_text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = size
	c.add_child(l)
	return c


func consume() -> void:
	_consumed = true
	modulate = Color(1, 1, 1, 0.35)
	mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN


func reset() -> void:
	_consumed = false
	modulate = Color.WHITE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
