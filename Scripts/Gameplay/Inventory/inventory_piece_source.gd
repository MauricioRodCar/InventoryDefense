class_name InventoryPieceSource
extends RefCounted
## Propietario de InventoryPiece disponibles para el jugador, todavía no
## colocadas en ningún InventoryGrid. No conoce representación visual ni
## reglas de colocación: solo qué piezas están ofrecidas ahora mismo.

const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")

signal piece_offered(piece: InventoryPiece)
signal piece_taken(piece: InventoryPiece)
signal piece_returned(piece: InventoryPiece)

var _available: Array[InventoryPiece] = []

func get_available_pieces() -> Array[InventoryPiece]:
	return _available.duplicate()

## Añade una pieza a la oferta actual.
func offer_piece(piece: InventoryPiece) -> void:
	_available.append(piece)
	piece_offered.emit(piece)

## El jugador empieza a interactuar con una pieza ofrecida: deja de estar disponible.
func take_piece(piece: InventoryPiece) -> bool:
	var index: int = _available.find(piece)
	if index == -1:
		return false
	_available.remove_at(index)
	piece_taken.emit(piece)
	return true

## La interacción con la pieza no terminó en una colocación válida: vuelve a la oferta.
func return_piece(piece: InventoryPiece) -> void:
	_available.append(piece)
	piece_returned.emit(piece)
