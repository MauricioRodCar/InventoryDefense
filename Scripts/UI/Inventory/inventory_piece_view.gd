class_name InventoryPieceView
extends Node2D
## Representación visual mínima de una InventoryPiece colocada: dibuja un
## rect por celda ocupada. No maneja input ni conoce reglas de colocación.

const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")

var _piece: InventoryPiece
var _cell_size: int = 32

func setup(piece: InventoryPiece, cell_size: int) -> void:
	_piece = piece
	_cell_size = cell_size
	queue_redraw()

func _draw() -> void:
	if _piece == null:
		return
	var color := _color_for_id(_piece.type_id)
	for cell in _piece.get_occupied_cells():
		var rect := Rect2(Vector2(cell) * _cell_size, Vector2.ONE * _cell_size)
		draw_rect(rect, color, true)

func _color_for_id(id: StringName) -> Color:
	var hash_value: int = absi(str(id).hash())
	return Color.from_hsv(float(hash_value % 360) / 360.0, 0.6, 0.85)
