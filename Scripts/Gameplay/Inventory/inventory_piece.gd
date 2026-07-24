class_name InventoryPiece
extends RefCounted
## Instancia concreta de un objeto en el inventario: qué forma usa y,
## si está colocada, en qué celda ancla. No valida colisiones ni límites:
## eso es responsabilidad de InventoryGrid. No emite señales.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

var id: StringName
var shape: ShapeData
var anchor = null # Vector2i cuando está colocada, null en caso contrario.

func _init(p_id: StringName, p_shape: ShapeData) -> void:
	id = p_id
	shape = p_shape

func is_placed() -> bool:
	return anchor != null

## Celdas absolutas que ocupa la pieza en el grid. Vacío si no está colocada.
func get_occupied_cells() -> Array[Vector2i]:
	if not is_placed():
		return []
	var occupied: Array[Vector2i] = []
	for cell in shape.get_cells():
		occupied.append(cell + anchor)
	return occupied

## Uso interno de InventoryGrid: único responsable de decidir colocación.
func _place_at(new_anchor: Vector2i) -> void:
	anchor = new_anchor

## Uso interno de InventoryGrid: único responsable de decidir remoción.
func _clear_placement() -> void:
	anchor = null
