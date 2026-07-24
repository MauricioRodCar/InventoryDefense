class_name InventoryGridBackground
extends Node2D
## Dibuja la malla vacía de un InventoryGrid: solo geometría de fondo.
## No conoce piezas ni estado de ocupación.

const CELL_COLOR := Color(0.22, 0.22, 0.26)
const BORDER_COLOR := Color(0.45, 0.45, 0.5)

var _width: int = 0
var _height: int = 0
var _cell_size: int = 32

func setup(width: int, height: int, cell_size: int) -> void:
	_width = width
	_height = height
	_cell_size = cell_size
	queue_redraw()

func _draw() -> void:
	for y in _height:
		for x in _width:
			var rect := Rect2(Vector2(x, y) * _cell_size, Vector2.ONE * _cell_size)
			draw_rect(rect, CELL_COLOR, true)
			draw_rect(rect, BORDER_COLOR, false)
