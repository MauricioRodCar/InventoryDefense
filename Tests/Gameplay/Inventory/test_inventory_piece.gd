extends RefCounted
## Tests básicos de InventoryPiece: estado de colocación y celdas ocupadas.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")

func test_pieza_nueva_no_esta_colocada(t) -> void:
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"piece_1", shape)
	t.assert_true(not piece.is_placed(), "una pieza nueva no debe estar colocada")
	t.assert_eq(piece.get_occupied_cells(), [], "una pieza sin colocar no ocupa celdas")

func test_place_at_marca_la_pieza_como_colocada(t) -> void:
	var shape := ShapeData.new(&"2x1", [Vector2i(0, 0), Vector2i(1, 0)])
	var piece := InventoryPiece.new(&"piece_1", shape)
	piece._place_at(Vector2i(3, 2))
	t.assert_true(piece.is_placed(), "tras _place_at la pieza debe estar colocada")
	t.assert_eq(
		piece.get_occupied_cells(),
		[Vector2i(3, 2), Vector2i(4, 2)],
		"las celdas ocupadas deben ser la forma desplazada por el ancla"
	)

func test_clear_placement_libera_la_pieza(t) -> void:
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"piece_1", shape)
	piece._place_at(Vector2i(0, 0))
	piece._clear_placement()
	t.assert_true(not piece.is_placed(), "tras _clear_placement la pieza no debe estar colocada")
	t.assert_eq(piece.get_occupied_cells(), [], "una pieza liberada no ocupa celdas")
