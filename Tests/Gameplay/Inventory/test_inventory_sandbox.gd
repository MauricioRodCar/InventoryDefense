extends RefCounted
## Tests de InventorySandbox: debe entregar un grid con una pieza inicial ya colocada.

const InventorySandbox = preload("res://Scripts/Gameplay/Inventory/inventory_sandbox.gd")
const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")

func test_create_starter_grid_devuelve_un_grid_con_una_pieza_colocada(t) -> void:
	var sandbox := InventorySandbox.new()

	var grid: InventoryGrid = sandbox.create_starter_grid()

	t.assert_eq(grid.get_pieces().size(), 1, "el grid inicial debe tener exactamente una pieza colocada")
	t.assert_true(grid.get_pieces()[0].is_placed(), "la pieza inicial debe estar marcada como colocada")
