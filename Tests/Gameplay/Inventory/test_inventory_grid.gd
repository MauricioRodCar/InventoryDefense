extends RefCounted
## Tests básicos de InventoryGrid: límites, solapamiento, colocar/remover y señales.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")

func test_colocar_pieza_dentro_de_limites(t) -> void:
	var grid := InventoryGrid.new(4, 4)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"p1", shape)
	var placed_events: Array = []
	grid.piece_placed.connect(func(p, anchor): placed_events.append([p, anchor]))

	var result: bool = grid.place_piece(piece, Vector2i(1, 1))

	t.assert_true(result, "colocar una pieza 1x1 dentro de límites debe devolver true")
	t.assert_eq(grid.get_piece_at(Vector2i(1, 1)), piece, "la celda debe apuntar a la pieza colocada")
	t.assert_eq(placed_events.size(), 1, "piece_placed debe emitirse exactamente una vez")

func test_colocar_fuera_de_limites_falla(t) -> void:
	var grid := InventoryGrid.new(2, 2)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"p1", shape)

	var result: bool = grid.place_piece(piece, Vector2i(5, 5))

	t.assert_true(not result, "colocar fuera de límites debe fallar")
	t.assert_true(not piece.is_placed(), "la pieza no debe quedar marcada como colocada")

func test_colocar_piezas_superpuestas_falla(t) -> void:
	var grid := InventoryGrid.new(4, 4)
	var shape := ShapeData.new(&"2x1", [Vector2i(0, 0), Vector2i(1, 0)])
	var piece_a := InventoryPiece.new(&"a", shape)
	var piece_b := InventoryPiece.new(&"b", shape)

	t.assert_true(grid.place_piece(piece_a, Vector2i(0, 0)), "la primera pieza debe colocarse sin problema")
	t.assert_true(not grid.place_piece(piece_b, Vector2i(1, 0)), "una pieza que se superpone debe fallar")

func test_remover_pieza_libera_celdas(t) -> void:
	var grid := InventoryGrid.new(3, 3)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"p1", shape)
	var removed_events: Array = []
	grid.piece_removed.connect(func(p): removed_events.append(p))
	grid.place_piece(piece, Vector2i(1, 1))

	var result: bool = grid.remove_piece(piece)

	t.assert_true(result, "remover una pieza colocada debe devolver true")
	t.assert_true(grid.get_piece_at(Vector2i(1, 1)) == null, "la celda debe quedar libre tras remover")
	t.assert_eq(removed_events.size(), 1, "piece_removed debe emitirse exactamente una vez")

	var piece_2 := InventoryPiece.new(&"p2", shape)
	t.assert_true(grid.place_piece(piece_2, Vector2i(1, 1)), "otra pieza debe poder ocupar la celda liberada")

func test_no_se_puede_colocar_una_pieza_ya_colocada(t) -> void:
	var grid := InventoryGrid.new(3, 3)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"p1", shape)
	grid.place_piece(piece, Vector2i(0, 0))

	var result: bool = grid.place_piece(piece, Vector2i(1, 1))

	t.assert_true(not result, "no se debe poder colocar una pieza que ya está colocada")

func test_get_piece_at_celda_vacia_retorna_null(t) -> void:
	var grid := InventoryGrid.new(2, 2)
	t.assert_true(grid.get_piece_at(Vector2i(0, 0)) == null, "una celda vacía debe devolver null")
