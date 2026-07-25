class_name InventoryInteractionController
extends Node
## Orquesta seleccionar/arrastrar/soltar una pieza, ya sea desde el
## InventoryGrid o desde un InventoryPieceSource. Traduce input de mouse en
## llamadas al dominio correspondiente, que sigue siendo la única autoridad
## sobre si una colocación u oferta es válida. No dibuja piezas permanentes
## ni conoce reglas de colocación u oferta: solo coordina la sesión de
## arrastre y a quién pertenece la pieza mientras dura.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")
const InventoryDragGhostView = preload("res://Scripts/UI/Inventory/inventory_drag_ghost_view.gd")

var grid_view: InventoryGridView
var source_view: InventoryPieceSourceView

var _grid: InventoryGrid
var _piece_source: InventoryPieceSource
var _dragged_piece: InventoryPiece
var _drag_from_source: bool = false
var _drag_origin_anchor: Vector2i
var _drag_grab_offset: Vector2
var _drag_grab_cell_offset: Vector2i
var _ghost: InventoryDragGhostView

func set_inventory_grid(grid: InventoryGrid) -> void:
	_grid = grid

func set_piece_source(source: InventoryPieceSource) -> void:
	_piece_source = source

func _unhandled_input(event: InputEvent) -> void:
	if _grid == null or grid_view == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_begin_drag()
		elif _dragged_piece != null:
			_end_drag()
	elif event is InputEventMouseMotion and _dragged_piece != null:
		_update_drag()

func _try_begin_drag() -> void:
	if _try_begin_drag_from_source():
		return
	_try_begin_drag_from_grid()

## Origen: una pieza aún no colocada, ofrecida por un InventoryPieceSource.
## TODO: no se preserva el punto exacto de agarre dentro de la pieza (a
## diferencia del drag desde el grid, ver _try_begin_drag_from_grid): tanto
## _drag_grab_cell_offset como _drag_grab_offset quedan en cero, así que la
## celda agarrada al soltar sobre el grid es siempre la (0,0) de la forma y
## el ghost no conserva el offset del clic. Pendiente de esta iteración,
## aceptado deliberadamente por el momento.
func _try_begin_drag_from_source() -> bool:
	if _piece_source == null or source_view == null:
		return false
	var local_pos: Vector2 = source_view.get_local_mouse_position()
	var piece: InventoryPiece = source_view.get_piece_at(local_pos)
	if piece == null or not _piece_source.take_piece(piece):
		return false
	_drag_from_source = true
	_dragged_piece = piece
	_drag_grab_cell_offset = Vector2i.ZERO
	_drag_grab_offset = Vector2.ZERO
	_ghost = _create_ghost(piece)
	_ghost.position = grid_view.get_local_mouse_position()
	return true

## Origen: una pieza ya colocada en InventoryGrid.
func _try_begin_drag_from_grid() -> bool:
	var local_pos: Vector2 = grid_view.get_local_mouse_position()
	var cell: Vector2i = grid_view.position_to_cell(local_pos)
	var piece: InventoryPiece = _grid.get_piece_at(cell)
	if piece == null:
		return false
	_drag_from_source = false
	_dragged_piece = piece
	_drag_origin_anchor = piece.anchor
	_drag_grab_cell_offset = cell - piece.anchor
	_drag_grab_offset = local_pos - grid_view.cell_to_position(piece.anchor)
	_take_piece_from_grid(piece)
	_ghost = _create_ghost(piece)
	_ghost.position = local_pos - _drag_grab_offset
	return true

func _update_drag() -> void:
	var local_pos: Vector2 = grid_view.get_local_mouse_position()
	_ghost.position = local_pos - _drag_grab_offset

func _end_drag() -> void:
	var piece: InventoryPiece = _dragged_piece
	var local_pos: Vector2 = grid_view.get_local_mouse_position()
	var cursor_cell: Vector2i = grid_view.position_to_cell(local_pos)
	var target_anchor: Vector2i = cursor_cell - _drag_grab_cell_offset
	if _grid.can_place(piece, target_anchor):
		_settle_piece_at(piece, target_anchor)
	elif _drag_from_source:
		_piece_source.return_piece(piece)
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
