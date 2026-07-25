class_name InventoryPlacementPreviewView
extends Node2D
## Feedback visual de si la celda candidata actual sería una colocación
## válida, mientras se arrastra una pieza. No conoce InventoryGrid ni evalúa
## reglas de colocación: solo dibuja según el State que se le indique desde
## fuera (InventoryInteractionController, apoyándose en
## InventoryGrid.can_place()).

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

## Estado general del preview. Aunque hoy solo se usan dos valores, la API
## se expresa como enum (no bool) para poder añadir más estados en el
## futuro sin romper el contrato público de esta clase.
enum State { VALID, INVALID }

const COLOR_BY_STATE := {
	State.VALID: Color(0.3, 1.0, 0.3, 0.45),
	State.INVALID: Color(1.0, 0.3, 0.3, 0.45),
}

var _shape: ShapeData
var _cell_size: int = 32
var _state: State = State.INVALID

func setup(shape: ShapeData, cell_size: int) -> void:
	_shape = shape
	_cell_size = cell_size
	queue_redraw()

## Reposiciona el preview sobre la celda ancla candidata (en píxeles, ya
## convertida por quien llama) y actualiza su estado visual.
func show_at(pixel_position: Vector2, state: State) -> void:
	position = pixel_position
	if state == _state:
		return
	_state = state
	queue_redraw()

func _draw() -> void:
	if _shape == null:
		return
	var color: Color = COLOR_BY_STATE[_state]
	for cell in _shape.get_cells():
		var rect := Rect2(Vector2(cell) * _cell_size, Vector2.ONE * _cell_size)
		draw_rect(rect, color, true)
