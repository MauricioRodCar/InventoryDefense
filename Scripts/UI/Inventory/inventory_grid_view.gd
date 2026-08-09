class_name InventoryGridView
extends Control
## Vista mínima de un InventoryGrid: refleja su estado escuchando sus
## señales y creando/destruyendo representaciones visuales de piezas.
## No conoce reglas de colocación ni valida nada; solo observa y dibuja.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryGridBackground = preload("res://Scripts/UI/Inventory/inventory_grid_background.gd")
const InventoryPieceView = preload("res://Scripts/UI/Inventory/inventory_piece_view.gd")

@export var cell_size: int = 32

@onready var _background: InventoryGridBackground = $GridBackground
@onready var _pieces_layer: Node2D = $PiecesLayer

var _grid: InventoryGrid
var _piece_views: Dictionary = {} # InventoryPiece -> InventoryPieceView

## Convierte una posición local (px) a la celda del grid que la contiene.
## Pura geometría de la representación visual; no valida límites del grid.
func position_to_cell(local_position: Vector2) -> Vector2i:
	return Vector2i(floori(local_position.x / cell_size), floori(local_position.y / cell_size))

## Convierte una celda del grid a su posición local (px), esquina superior izquierda.
func cell_to_position(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size

func set_inventory_grid(grid: InventoryGrid) -> void:
	_disconnect_grid()
	_clear_piece_views()

	_grid = grid
	if _grid == null:
		return

	_grid.piece_placed.connect(_on_piece_placed)
	_grid.piece_removed.connect(_on_piece_removed)
	_grid.grid_expanded.connect(_on_grid_expanded)
	_background.setup(_grid.get_width(), _grid.get_height(), cell_size)
	custom_minimum_size = Vector2(_grid.get_width() * cell_size, _grid.get_height() * cell_size)
	_render_all()

func _exit_tree() -> void:
	_disconnect_grid()

func _render_all() -> void:
	for piece in _grid.get_pieces():
		_add_piece_view(piece)

func _on_piece_placed(piece: InventoryPiece, _anchor: Vector2i) -> void:
	_add_piece_view(piece)

func _on_piece_removed(piece: InventoryPiece) -> void:
	var view: InventoryPieceView = _piece_views.get(piece)
	if view == null:
		return
	_piece_views.erase(piece)
	view.queue_free()

func _on_grid_expanded(new_width: int, new_height: int) -> void:
	_background.setup(new_width, new_height, cell_size)
	custom_minimum_size = Vector2(new_width * cell_size, new_height * cell_size)

func _add_piece_view(piece: InventoryPiece) -> void:
	if _piece_views.has(piece):
		return
	var view := InventoryPieceView.new()
	_pieces_layer.add_child(view)
	view.setup(piece, cell_size)
	_piece_views[piece] = view

func _clear_piece_views() -> void:
	for view in _piece_views.values():
		view.queue_free()
	_piece_views.clear()

func _disconnect_grid() -> void:
	if _grid == null:
		return
	if _grid.piece_placed.is_connected(_on_piece_placed):
		_grid.piece_placed.disconnect(_on_piece_placed)
	if _grid.piece_removed.is_connected(_on_piece_removed):
		_grid.piece_removed.disconnect(_on_piece_removed)
	if _grid.grid_expanded.is_connected(_on_grid_expanded):
		_grid.grid_expanded.disconnect(_on_grid_expanded)
