class_name InventoryInteractionController
extends Node
## Orquesta seleccionar/arrastrar/soltar una pieza del inventario. Traduce
## input de mouse en llamadas a InventoryGrid, que sigue siendo la única
## autoridad sobre si una colocación es válida. No dibuja piezas permanentes
## (responsabilidad de InventoryGridView) ni conoce reglas de colocación
## (responsabilidad de InventoryGrid): solo coordina la sesión de arrastre.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryDragGhostView = preload("res://Scripts/UI/Inventory/inventory_drag_ghost_view.gd")

var grid_view: InventoryGridView

var _grid: InventoryGrid
var _dragged_piece: InventoryPiece
var _drag_origin_anchor: Vector2i
var _drag_grab_offset: Vector2
var _drag_grab_cell_offset: Vector2i
var _ghost: InventoryDragGhostView

func set_inventory_grid(grid: InventoryGrid) -> void:
	_grid = grid

func _unhandled_input(event: InputEvent) -> void:
	if _grid == null or grid_view == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = grid_view.get_local_mouse_position()
		if event.pressed:
			_try_begin_drag(local_pos)
		elif _dragged_piece != null:
			_end_drag(local_pos)
	elif event is InputEventMouseMotion and _dragged_piece != null:
		_update_drag(grid_view.get_local_mouse_position())

func _try_begin_drag(local_pos: Vector2) -> void:
	var cell: Vector2i = grid_view.position_to_cell(local_pos)
	var piece: InventoryPiece = _grid.get_piece_at(cell)
	if piece == null:
		return
	_dragged_piece = piece
	_drag_origin_anchor = piece.anchor
	_drag_grab_cell_offset = cell - piece.anchor
	_drag_grab_offset = local_pos - grid_view.cell_to_position(piece.anchor)
	_take_piece_from_grid(piece)
	_ghost = _create_ghost(piece)
	_ghost.position = local_pos - _drag_grab_offset

func _update_drag(local_pos: Vector2) -> void:
	_ghost.position = local_pos - _drag_grab_offset

func _end_drag(local_pos: Vector2) -> void:
	var piece: InventoryPiece = _dragged_piece
	var cursor_cell: Vector2i = grid_view.position_to_cell(local_pos)
	var target_anchor: Vector2i = cursor_cell - _drag_grab_cell_offset
	if _grid.can_place(piece, target_anchor):
		_settle_piece_at(piece, target_anchor)
	else:
		_settle_piece_at(piece, _drag_origin_anchor)
	_destroy_ghost()
	_dragged_piece = null

## Aislado para poder sustituirse por una operación atómica (p. ej. un futuro
## InventoryGrid.move_piece) sin cambiar el resto del flujo de arrastre.
func _take_piece_from_grid(piece: InventoryPiece) -> void:
	_grid.remove_piece(piece)

## Ver _take_piece_from_grid: mismo motivo de aislamiento.
func _settle_piece_at(piece: InventoryPiece, anchor: Vector2i) -> void:
	_grid.place_piece(piece, anchor)

func _create_ghost(piece: InventoryPiece) -> InventoryDragGhostView:
	var ghost := InventoryDragGhostView.new()
	grid_view.add_child(ghost)
	ghost.setup(piece.shape, grid_view.cell_size)
	return ghost

func _destroy_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
