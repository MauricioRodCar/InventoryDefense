class_name InventorySandbox
extends RefCounted
## Proveedor temporal de contenido de inventario para esta vertical slice.
## Única responsabilidad: construir un InventoryGrid de prueba con una pieza
## ya colocada. Será reemplazado por tienda, cofres o recompensas cuando
## existan; no debe acumular más lógica mientras tanto.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")

func create_starter_grid() -> InventoryGrid:
	var grid := InventoryGrid.new(6, 6)
	var shape := ShapeData.new(&"2x2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])
	var piece := InventoryPiece.new(&"square", shape)
	grid.place_piece(piece, Vector2i(0, 0))
	return grid
