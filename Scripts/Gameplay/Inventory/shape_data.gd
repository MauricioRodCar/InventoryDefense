class_name ShapeData
extends Resource
## Geometría pura de una forma de inventario: qué celdas relativas ocupa.
## No conoce grids, piezas ni posiciones absolutas.

@export var id: StringName = &""
@export var cells: Array[Vector2i] = []

func _init(p_id: StringName = &"", p_cells: Array[Vector2i] = []) -> void:
	id = p_id
	cells = p_cells

## Devuelve las celdas ocupadas rotadas 90° * rotation_steps (sentido horario),
## normalizadas para que el bounding box vuelva a empezar en (0,0).
func get_cells(rotation_steps: int = 0) -> Array[Vector2i]:
	var steps: int = ((rotation_steps % 4) + 4) % 4
	var result: Array[Vector2i] = cells.duplicate()
	for i in steps:
		result = _rotate_once(result)
	return _normalize(result)

func _rotate_once(source: Array[Vector2i]) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []
	for cell in source:
		rotated.append(Vector2i(cell.y, -cell.x))
	return rotated

func _normalize(source: Array[Vector2i]) -> Array[Vector2i]:
	if source.is_empty():
		return source
	var min_x: int = source[0].x
	var min_y: int = source[0].y
	for cell in source:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
	var normalized: Array[Vector2i] = []
	for cell in source:
		normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return normalized
