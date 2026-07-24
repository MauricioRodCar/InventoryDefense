extends Node2D
## CÓDIGO TEMPORAL DE INTEGRACIÓN — no es gameplay real.
## Único propósito: validar manualmente InventoryGridView (render inicial +
## reactividad a piece_placed/piece_removed) mientras no existe todavía un
## flujo real que pueble el inventario. Reemplazar por la lógica de arranque
## real del juego cuando exista; no darle más responsabilidades mientras tanto.
##
## Crea un InventoryGrid de ejemplo, coloca piezas antes y después de
## conectar la vista, y remueve una pieza tras un breve retraso para
## verificar la actualización reactiva.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

@onready var _grid_view: InventoryGridView = $InventoryGridView

var _grid: InventoryGrid
var _piece_l: InventoryPiece

func _ready() -> void:
	_grid = InventoryGrid.new(6, 6)

	var shape_square := ShapeData.new(&"2x2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])
	var shape_l := ShapeData.new(&"L", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)])
	var shape_single := ShapeData.new(&"1x1", [Vector2i(0, 0)])

	var piece_square := InventoryPiece.new(&"square", shape_square)
	_grid.place_piece(piece_square, Vector2i(0, 0))

	_grid_view.set_inventory_grid(_grid)

	_piece_l = InventoryPiece.new(&"ele", shape_l)
	_grid.place_piece(_piece_l, Vector2i(3, 0))

	var piece_single := InventoryPiece.new(&"punto", shape_single)
	_grid.place_piece(piece_single, Vector2i(2, 4))

	await get_tree().create_timer(2.0).timeout
	_grid.remove_piece(_piece_l)
