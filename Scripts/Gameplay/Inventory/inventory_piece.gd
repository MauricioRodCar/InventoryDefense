class_name InventoryPiece
extends RefCounted
## Instancia concreta de un objeto en el inventario: qué forma usa y,
## si está colocada, en qué celda ancla. No valida colisiones ni límites:
## eso es responsabilidad de InventoryGrid. No emite señales.
##
## id y type_id cumplen roles distintos: type_id identifica el tipo de
## pieza (compartible entre múltiples instancias del mismo tipo, p. ej.
## &"square"; mismo rol que WeaponData.id/EnemyData.id en Combat), mientras
## que id identifica la instancia concreta y se genera automáticamente al
## construirse, para que InventoryGrid pueda usarlo como clave única en su
## diccionario interno aunque dos piezas ofrecidas compartan type_id.
##
## rank empieza en 1 y solo sube fusionando dos piezas compatibles vía
## InventoryGrid.merge_pieces, hasta MAX_RANK.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

const MAX_RANK := 3

static var _next_instance_id: int = 0

var id: StringName
var type_id: StringName
var shape: ShapeData
var anchor = null # Vector2i cuando está colocada, null en caso contrario.
var rank: int = 1

func _init(p_type_id: StringName, p_shape: ShapeData) -> void:
	type_id = p_type_id
	shape = p_shape
	id = StringName("piece_%d" % _next_instance_id)
	_next_instance_id += 1

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

## Uso interno de InventoryGrid: único responsable de decidir fusión.
func _increase_rank() -> void:
	rank += 1
