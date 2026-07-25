class_name InventoryDragGhostView
extends Node2D
## Representación visual temporal de una pieza mientras se arrastra, antes
## de que InventoryGrid decida su colocación final. A diferencia de
## InventoryPieceView, no representa una InventoryPiece colocada: solo
## dibuja la geometría de un ShapeData en la posición del propio nodo, que
## el arrastre actualiza libremente. No conoce InventoryGrid ni reglas de
## colocación.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

const GHOST_COLOR := Color(1, 1, 1, 0.5)

var _shape: ShapeData
var _cell_size: int = 32

func setup(shape: ShapeData, cell_size: int) -> void:
	_shape = shape
	_cell_size = cell_size
	queue_redraw()

func _draw() -> void:
	if _shape == null:
		return
	for cell in _shape.get_cells():
		var rect := Rect2(Vector2(cell) * _cell_size, Vector2.ONE * _cell_size)
		draw_rect(rect, GHOST_COLOR, true)
