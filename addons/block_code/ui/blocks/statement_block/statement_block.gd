@tool
class_name StatementBlock
extends Block

@onready var _background := %Background
@onready var _hbox := %HBoxContainer

var arg_name_to_param_input_dict: Dictionary
var args_to_add_after_format: Dictionary  # Only used when loading


func _ready():
	super()

	if block_resource.block_type != Types.BlockType.STATEMENT:
		_background.show_top = false
	_background.color = color

	format()

	for arg_name in arg_name_to_param_input_dict:
		if arg_name in args_to_add_after_format:
			var argument = args_to_add_after_format[arg_name]
			if argument is Block:
				arg_name_to_param_input_dict[arg_name].snap_point.add_child(argument)
			else:
				arg_name_to_param_input_dict[arg_name].set_raw_input(argument)


func _on_drag_drop_area_mouse_down():
	_drag_started()


static func get_block_class():
	return "StatementBlock"


static func get_scene_path():
	return "res://addons/block_code/ui/blocks/statement_block/statement_block.tscn"


func format():
	arg_name_to_param_input_dict = format_string(self, %HBoxContainer, block_resource.block_format, block_resource.defaults)


static func format_string(parent_block: Block, attach_to: Node, string: String, _defaults: Dictionary) -> Dictionary:
	var _arg_name_to_param_input_dict = {}
	var regex = RegEx.new()
	regex.compile("\\[([^\\]]+)\\]|\\{([^}]+)\\}")  # Capture things of format {test} or [test]
	var results := regex.search_all(string)

	var start: int = 0
	for result in results:
		var label_text := string.substr(start, result.get_start() - start)
		if label_text != "":
			var label = Label.new()
			label.add_theme_color_override("font_color", Color.WHITE)
			label.text = label_text
			attach_to.add_child(label)

		var param := result.get_string()
		var copy_block: bool = param[0] == "["
		param = param.substr(1, param.length() - 2)

		var split := param.split(": ")
		var param_name := split[0]
		var param_type_str := split[1]

		var param_type = null
		var option := false
		if param_type_str == "OPTION":  # Easy way to specify dropdown option
			option = true
		else:
			param_type = Types.STRING_TO_VARIANT_TYPE[param_type_str]

		var param_default = null
		if _defaults.has(param_name):
			param_default = _defaults[param_name]

		var param_node: Node

		if copy_block:
			var parameter_output: ParameterOutput = preload("res://addons/block_code/ui/blocks/utilities/parameter_output/parameter_output.tscn").instantiate()
			parameter_output.name = "ParameterOutput%d" % start  # Unique path
			var entry_statement = parent_block.block_resource.statement
			var block_resource = BlockResource.new()
			block_resource.block_name = entry_statement + "_" + param_name
			block_resource.block_format = param_name
			block_resource.statement = param_name
			block_resource.variant_type = param_type
			block_resource.category = parent_block.block_resource.category
			parameter_output.block_params = {"block_resource": block_resource, "color": parent_block.color, "scope": entry_statement if parent_block is EntryBlock else ""}
			parameter_output.block = parent_block
			attach_to.add_child(parameter_output)
		else:
			var parameter_input: ParameterInput = preload("res://addons/block_code/ui/blocks/utilities/parameter_input/parameter_input.tscn").instantiate()
			parameter_input.name = "ParameterInput%d" % start  # Unique path
			parameter_input.placeholder = param_name
			if param_type != null:
				parameter_input.variant_type = param_type
			elif option:
				parameter_input.option = true
			parameter_input.modified.connect(func(): parent_block.modified.emit())

			attach_to.add_child(parameter_input)

			if param_default != null:
				parameter_input.set_raw_input(param_default)

			_arg_name_to_param_input_dict[param_name] = parameter_input

		start = result.get_end()

	var label_text := string.substr(start)
	if label_text != "":
		var label = Label.new()
		label.add_theme_color_override("font_color", Color.WHITE)
		label.text = label_text
		attach_to.add_child(label)

	return _arg_name_to_param_input_dict
