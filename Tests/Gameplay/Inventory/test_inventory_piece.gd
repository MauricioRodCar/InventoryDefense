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

func test_dos_piezas_del_mismo_tipo_comparten_type_id_pero_no_id(t) -> void:
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece_a := InventoryPiece.new(&"square", shape)
	var piece_b := InventoryPiece.new(&"square", shape)
	t.assert_eq(piece_a.type_id, &"square", "type_id debe reflejar el tipo pasado al constructor")
	t.assert_eq(piece_b.type_id, &"square", "dos piezas del mismo tipo deben compartir type_id")
	t.assert_true(piece_a.id != piece_b.id, "dos instancias distintas deben tener id distinto aunque compartan type_id")

func test_pieza_nueva_arranca_en_rango_1(t) -> void:
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var piece := InventoryPiece.new(&"piece_1", shape)
	t.assert_eq(piece.rank, 1, "una pieza nueva debe arrancar en rank == 1")
