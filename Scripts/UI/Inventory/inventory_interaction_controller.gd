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
const InventoryPlacementPreviewView = preload("res://Scripts/UI/Inventory/inventory_placement_preview_view.gd")

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
var _preview: InventoryPlacementPreviewView
var _last_preview_anchor = null # Vector2i cuando hay una evaluación previa, null al iniciar cada drag.

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
	var grid_local_pos: Vector2 = grid_view.get_local_mouse_position()
	_preview = _create_preview(piece)
	_ghost = _create_ghost(piece)
	_ghost.position = grid_local_pos
	_update_placement_preview(grid_local_pos)
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
	_preview = _create_preview(piece)
	_ghost = _create_ghost(piece)
	_ghost.position = local_pos - _drag_grab_offset
	_update_placement_preview(local_pos)
	return true

func _update_drag() -> void:
	var local_pos: Vector2 = grid_view.get_local_mouse_position()
	_ghost.position = local_pos - _drag_grab_offset
	_update_placement_preview(local_pos)

## Recalcula la celda ancla candidata bajo el cursor y, solo si cambió
## respecto a la última evaluada, vuelve a consultar
## InventoryGrid.can_place() y empuja el nuevo estado al preview. Evita
## invocar can_place() en cada píxel de movimiento del ratón: el número de
## consultas queda acotado a las celdas distintas que el cursor cruza.
func _update_placement_preview(local_pos: Vector2) -> void:
	var cursor_cell: Vector2i = grid_view.position_to_cell(local_pos)
	var candidate_anchor: Vector2i = cursor_cell - _drag_grab_cell_offset
	if candidate_anchor == _last_preview_anchor:
		return
	_last_preview_anchor = candidate_anchor
	var state: InventoryPlacementPreviewView.State = InventoryPlacementPreviewView.State.VALID \
		if _grid.can_place(_dragged_piece, candidate_anchor) \
		else InventoryPlacementPreviewView.State.INVALID
	_preview.show_at(grid_view.cell_to_position(candidate_anchor), state)

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
	_destroy_preview()
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

func _create_preview(piece: InventoryPiece) -> InventoryPlacementPreviewView:
	var preview := InventoryPlacementPreviewView.new()
	grid_view.add_child(preview)
	preview.setup(piece.shape, grid_view.cell_size)
	return preview

func _destroy_preview() -> void:
	if _preview != null:
		_preview.queue_free()
		_preview = null
	_last_preview_anchor = null
