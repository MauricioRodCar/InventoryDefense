class_name InventoryPieceSourceView
extends Control
## Vista mínima de un InventoryPieceSource: refleja qué piezas están
## disponibles dibujándolas en una fila, y traduce posición de mouse en
## pieza para que el controller pueda iniciar un arrastre. No conoce
## reglas de oferta ni de colocación; solo observa el dominio y dibuja.

const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryPieceSourceSlotView = preload("res://Scripts/UI/Inventory/inventory_piece_source_slot_view.gd")

const SLOT_WIDTH_CELLS: int = 4 # ancho reservado por pieza ofrecida, en celdas

@export var cell_size: int = 32

@onready var _items_layer: Node2D = $ItemsLayer

var _source: InventoryPieceSource
var _slot_views: Dictionary = {} # InventoryPiece -> InventoryPieceSourceSlotView

func set_piece_source(source: InventoryPieceSource) -> void:
	_disconnect_source()
	_clear_slot_views()

	_source = source
	if _source == null:
		return

	_source.piece_offered.connect(_on_piece_offered)
	_source.piece_taken.connect(_on_piece_taken)
	_source.piece_returned.connect(_on_piece_returned)
	_render_all()

func _exit_tree() -> void:
	_disconnect_source()

## Traduce una posición local (px) a la pieza ofrecida dibujada ahí, o null.
func get_piece_at(local_position: Vector2) -> InventoryPiece:
	if _source == null or local_position.x < 0 or local_position.y < 0:
		return null
	var pieces: Array[InventoryPiece] = _source.get_available_pieces()
	var index: int = floori(local_position.x / (SLOT_WIDTH_CELLS * cell_size))
	if index < 0 or index >= pieces.size():
		return null
	return pieces[index]

func _render_all() -> void:
	for piece in _source.get_available_pieces():
		_add_slot_view(piece)
	_relayout()

func _on_piece_offered(piece: InventoryPiece) -> void:
	_add_slot_view(piece)
	_relayout()

func _on_piece_taken(piece: InventoryPiece) -> void:
	_remove_slot_view(piece)
	_relayout()

func _on_piece_returned(piece: InventoryPiece) -> void:
	_add_slot_view(piece)
	_relayout()

func _add_slot_view(piece: InventoryPiece) -> void:
	if _slot_views.has(piece):
		return
	var view := InventoryPieceSourceSlotView.new()
	_items_layer.add_child(view)
	view.setup(piece, cell_size)
	_slot_views[piece] = view

func _remove_slot_view(piece: InventoryPiece) -> void:
	var view: InventoryPieceSourceSlotView = _slot_views.get(piece)
	if view == null:
		return
	_slot_views.erase(piece)
	view.queue_free()

## Reordena las piezas ofrecidas en fila, en el mismo orden que expone
## get_piece_at, para que el hit-test siga siendo coherente con el dibujo.
func _relayout() -> void:
	var index: int = 0
	for piece in _source.get_available_pieces():
		var view: InventoryPieceSourceSlotView = _slot_views.get(piece)
		if view != null:
			view.position = Vector2(index * SLOT_WIDTH_CELLS * cell_size, 0)
		index += 1

func _clear_slot_views() -> void:
	for view in _slot_views.values():
		view.queue_free()
	_slot_views.clear()

func _disconnect_source() -> void:
	if _source == null:
		return
	if _source.piece_offered.is_connected(_on_piece_offered):
		_source.piece_offered.disconnect(_on_piece_offered)
	if _source.piece_taken.is_connected(_on_piece_taken):
		_source.piece_taken.disconnect(_on_piece_taken)
	if _source.piece_returned.is_connected(_on_piece_returned):
		_source.piece_returned.disconnect(_on_piece_returned)
