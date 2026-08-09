class_name InventoryGrid
extends RefCounted
## Contenedor acotado de InventoryPiece. Única fuente de verdad sobre qué
## celda está ocupada por qué pieza, y único emisor de señales del dominio
## de inventario. Los límites (_width/_height) solo pueden crecer, nunca
## encoger, vía expand() — mantiene un único camino de mutación con señal,
## igual que place_piece/remove_piece sobre _cells/_pieces.

const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")

signal piece_placed(piece: InventoryPiece, anchor: Vector2i)
signal piece_removed(piece: InventoryPiece)
signal grid_expanded(new_width: int, new_height: int)

var _width: int
var _height: int

var _cells: Dictionary = {} # Vector2i -> InventoryPiece
var _pieces: Dictionary = {} # StringName -> InventoryPiece

func _init(p_width: int, p_height: int) -> void:
	_width = p_width
	_height = p_height

func get_width() -> int:
	return _width

func get_height() -> int:
	return _height

## Agranda el grid en runtime. Solo crece, nunca encoge: reducir un grid con
## piezas ya colocadas plantearía qué hacer con las piezas que quedan fuera
## de los nuevos límites, un problema que ningún consumidor actual necesita
## resolver.
func expand(additional_width: int, additional_height: int) -> void:
	assert(additional_width >= 0 and additional_height >= 0)
	assert(additional_width > 0 or additional_height > 0)
	_width += additional_width
	_height += additional_height
	grid_expanded.emit(_width, _height)

func is_within_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _width and cell.y < _height

## True si la pieza cabría en anchor: dentro de límites y sin solapar piezas ya colocadas.
func can_place(piece: InventoryPiece, anchor: Vector2i) -> bool:
	if piece == null or piece.shape == null:
		return false
	for offset in piece.shape.get_cells():
		var cell: Vector2i = anchor + offset
		if not is_within_bounds(cell):
			return false
		if _cells.has(cell):
			return false
	return true

func place_piece(piece: InventoryPiece, anchor: Vector2i) -> bool:
	if piece.is_placed():
		return false
	if not can_place(piece, anchor):
		return false
	for offset in piece.shape.get_cells():
		_cells[anchor + offset] = piece
	piece._place_at(anchor)
	_pieces[piece.id] = piece
	piece_placed.emit(piece, anchor)
	return true

func remove_piece(piece: InventoryPiece) -> bool:
	if piece == null or not piece.is_placed():
		return false
	for cell in piece.get_occupied_cells():
		_cells.erase(cell)
	piece._clear_placement()
	_pieces.erase(piece.id)
	piece_removed.emit(piece)
	return true

func get_piece_at(cell: Vector2i) -> InventoryPiece:
	return _cells.get(cell)

func get_pieces() -> Array[InventoryPiece]:
	var result: Array[InventoryPiece] = []
	for piece in _pieces.values():
		result.append(piece)
	return result
