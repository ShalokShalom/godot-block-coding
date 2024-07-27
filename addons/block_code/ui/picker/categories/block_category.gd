class_name BlockCategory
extends RefCounted

var name: String
var block_list: Array[BlockResource]
var color: Color
var order: int


func _init(p_name: String = "", p_color: Color = Color.WHITE, p_order: int = 0, p_block_list: Array[BlockResource] = []):
	name = p_name
	block_list = p_block_list
	color = p_color
	order = p_order
