extends Node2D
## Composition root de la vertical slice de interacción de inventario.
## Construye el contenido inicial mediante InventorySandbox y conecta el
## dominio con la vista (InventoryGridView) y el controlador de interacción
## (InventoryInteractionController). No contiene lógica de juego propia.

const InventorySandbox = preload("res://Scripts/Gameplay/Inventory/inventory_sandbox.gd")

@onready var _grid_view: InventoryGridView = $InventoryGridView
@onready var _interaction_controller: InventoryInteractionController = $InventoryInteractionController

func _ready() -> void:
	var sandbox := InventorySandbox.new()
	var grid := sandbox.create_starter_grid()

	_grid_view.set_inventory_grid(grid)
	_interaction_controller.grid_view = _grid_view
	_interaction_controller.set_inventory_grid(grid)
