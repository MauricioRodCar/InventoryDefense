extends Node2D
## Composition root de la vertical slice de interacción de inventario.
## Construye el InventoryGrid y una fuente de piezas de prueba, y conecta el
## dominio con las vistas (InventoryGridView, InventoryPieceSourceView) y el
## controlador de interacción (InventoryInteractionController). No contiene
## lógica de juego propia.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPieceSourceSandbox = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source_sandbox.gd")

@onready var _grid_view: InventoryGridView = $InventoryGridView
@onready var _source_view: InventoryPieceSourceView = $InventoryPieceSourceView
@onready var _interaction_controller: InventoryInteractionController = $InventoryInteractionController

func _ready() -> void:
	var grid := InventoryGrid.new(6, 6)
	var piece_source := InventoryPieceSourceSandbox.new()

	_grid_view.set_inventory_grid(grid)
	_source_view.set_piece_source(piece_source)

	_interaction_controller.grid_view = _grid_view
	_interaction_controller.source_view = _source_view
	_interaction_controller.set_inventory_grid(grid)
	_interaction_controller.set_piece_source(piece_source)
