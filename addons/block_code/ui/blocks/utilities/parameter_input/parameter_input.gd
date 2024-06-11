@tool
class_name ParameterInput
extends MarginContainer

signal text_modified

@export var placeholder: String = "Parameter":
	set = _set_placeholder

@export var block_path: NodePath

@export var block_type: Types.BlockType = Types.BlockType.STRING

var block: Block

@onready var _line_edit := %LineEdit
@onready var snap_point := %SnapPoint


func set_plain_text(new_text):
	_line_edit.text = new_text


func get_plain_text():
	return _line_edit.text


func _set_placeholder(new_placeholder: String) -> void:
	placeholder = new_placeholder

	if not is_node_ready():
		return

	_line_edit.placeholder_text = placeholder


func _ready():
	_set_placeholder(placeholder)

	if block == null:
		block = get_node_or_null(block_path)
	snap_point.block = block
	snap_point.block_type = block_type

	# Do something with block_type to restrict input


func get_snapped_block() -> Block:
	return snap_point.get_snapped_block()


func get_string() -> String:
	var snapped_block: Block = get_snapped_block()
	if snapped_block:
		return snapped_block.get_parameter_string()

	return _line_edit.text


func _on_line_edit_text_changed(new_text):
	text_modified.emit()
