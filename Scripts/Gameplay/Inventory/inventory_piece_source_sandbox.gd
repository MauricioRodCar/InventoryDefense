class_name InventoryPieceSourceSandbox
extends InventoryPieceSource
## Fuente de piezas de prueba para esta vertical slice. Única
## responsabilidad: ofrecer un puñado de piezas variadas al construirse.
## Reemplaza a InventorySandbox; será sustituida por tienda/cofres/
## recompensas cuando existan, y no debe acumular más lógica mientras tanto.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

func _init() -> void:
	offer_piece(InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])))
	offer_piece(InventoryPiece.new(&"bar", ShapeData.new(&"3x1", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])))
	offer_piece(InventoryPiece.new(&"corner", ShapeData.new(&"corner", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)])))
