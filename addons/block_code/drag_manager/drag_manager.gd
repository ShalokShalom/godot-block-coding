@tool
class_name DragManager
extends Control

@export var picker_path: NodePath
@export var block_canvas_path: NodePath

var drag_offset: Vector2
var dragging: Block = null

var previewing_snap_point: SnapPoint = null
var preview_block: Control = null

var _picker: Picker
var _block_canvas: BlockCanvas


func _ready():
	_picker = get_node(picker_path)
	_block_canvas = get_node(block_canvas_path)


func _process(_delta):
	var mouse_pos: Vector2 = get_local_mouse_position()
	if dragging:
		dragging.position = mouse_pos - drag_offset

		var dragging_global_pos: Vector2 = dragging.get_global_rect().position

		# TODO: check if dropped snap point is occupied
		# if so, replace with this node and attach the previous one
		# to this node's bottom snap

		# Find closest snap point not child of current node
		var closest_snap_point: SnapPoint = null
		var closest_dist: float = INF
		var snap_points: Array[Node] = get_tree().get_nodes_in_group("snap_point")
		for n in snap_points:
			if n is SnapPoint:
				var snap_point: SnapPoint = n as SnapPoint

				if snap_point.block.on_canvas:
					var snap_global_pos: Vector2 = snap_point.get_global_rect().position
					var temp_dist: float = dragging_global_pos.distance_to(snap_global_pos)
					if temp_dist < closest_dist:
						# Check if any parent node is this node
						var is_child: bool = false
						var parent = snap_point
						while parent is SnapPoint:
							if parent.block == dragging:
								is_child = true
								break

							parent = parent.block.get_parent()

						if not is_child:
							closest_dist = temp_dist
							closest_snap_point = snap_point

		if closest_dist > 80.0:
			closest_snap_point = null

		if closest_snap_point != previewing_snap_point:
			_update_preview(closest_snap_point)


func _update_preview(snap_point: SnapPoint):
	previewing_snap_point = snap_point

	if preview_block:
		preview_block.queue_free()
		preview_block = null

	if previewing_snap_point:
		# Make preview block
		preview_block = MarginContainer.new()
		preview_block.custom_minimum_size.y = dragging.get_global_rect().size.y

		previewing_snap_point.add_child(preview_block)


func drag_block(block: Block, copied_from: Block = null):
	var new_pos: Vector2 = -get_global_rect().position

	if copied_from:
		new_pos += copied_from.get_global_rect().position
	else:
		new_pos += block.get_global_rect().position

	var parent = block.get_parent()
	if parent:
		parent.remove_child(block)

	block.position = new_pos
	block.on_canvas = false
	add_child(block)

	drag_offset = get_local_mouse_position() - block.position
	dragging = block


func copy_block(block: Block) -> Block:
	return block.duplicate(8)  # use instantiation


func copy_picked_block_and_drag(block: Block):
	var new_block: Block = copy_block(block)

	drag_block(new_block, block)


func drag_ended():
	if dragging:
		var block_rect: Rect2 = dragging.get_global_rect()

		# Check if in BlockCanvas
		var block_canvas_rect: Rect2 = _block_canvas.get_global_rect()
		if block_canvas_rect.encloses(block_rect):
			dragging.disconnect_drag()  # disconnect previous drag signal connections
			dragging.drag_started.connect(drag_block)
			remove_child(dragging)
			dragging.on_canvas = true

			if previewing_snap_point:
				# Can snap block
				preview_block.queue_free()
				preview_block = null
				previewing_snap_point.add_child(dragging)
			else:
				# Block goes on screen somewhere
				dragging.position = (
					get_global_mouse_position() - block_canvas_rect.position - drag_offset
				)
				_block_canvas.add_block(dragging)
		else:
			dragging.queue_free()

		dragging = null
