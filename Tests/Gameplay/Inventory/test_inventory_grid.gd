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

func test_dos_piezas_del_mismo_type_id_no_se_pisan(t) -> void:
	var grid := InventoryGrid.new(4, 4)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece_a := InventoryPiece.new(&"square", shape)
	var piece_b := InventoryPiece.new(&"square", shape)

	grid.place_piece(piece_a, Vector2i(0, 0))
	grid.place_piece(piece_b, Vector2i(1, 0))

	t.assert_eq(grid.get_pieces().size(), 2, "dos piezas del mismo type_id colocadas en celdas distintas no deben pisarse en _pieces")

func test_expand_agranda_los_limites(t) -> void:
	var grid := InventoryGrid.new(2, 2)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"p1", shape)

	t.assert_true(not grid.can_place(piece, Vector2i(2, 0)), "la celda (2, 0) no debe existir todavía en un grid de 2x2")

	grid.expand(2, 0)

	t.assert_eq(grid.get_width(), 4, "expand debe agrandar el ancho")
	t.assert_eq(grid.get_height(), 2, "expand no debe modificar el alto si additional_height es 0")
	t.assert_true(grid.can_place(piece, Vector2i(2, 0)), "la celda (2, 0) debe estar disponible tras expandir el ancho")
	t.assert_true(grid.place_piece(piece, Vector2i(2, 0)), "debe poder colocarse una pieza en la columna nueva")

func test_expand_emite_grid_expanded_una_vez(t) -> void:
	var grid := InventoryGrid.new(2, 2)
	var expanded_events: Array = []
	grid.grid_expanded.connect(func(new_width, new_height): expanded_events.append([new_width, new_height]))

	grid.expand(1, 3)

	t.assert_eq(expanded_events.size(), 1, "grid_expanded debe emitirse exactamente una vez")
	t.assert_eq(expanded_events[0][0], 3, "grid_expanded debe reportar el nuevo ancho")
	t.assert_eq(expanded_events[0][1], 5, "grid_expanded debe reportar el nuevo alto")
