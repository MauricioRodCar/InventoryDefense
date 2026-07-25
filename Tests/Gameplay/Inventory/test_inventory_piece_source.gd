extends RefCounted
## Tests de InventoryPieceSource: ofrecer, tomar y devolver piezas.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")

func test_offer_piece_la_agrega_a_las_disponibles_y_emite_senal(t) -> void:
	var source := InventoryPieceSource.new()
	var piece := InventoryPiece.new(&"p1", ShapeData.new(&"1x1", [Vector2i(0, 0)]))
	var offered_events: Array = []
	source.piece_offered.connect(func(p): offered_events.append(p))

	source.offer_piece(piece)

	t.assert_eq(source.get_available_pieces().size(), 1, "la pieza ofrecida debe aparecer en las disponibles")
	t.assert_eq(offered_events.size(), 1, "piece_offered debe emitirse exactamente una vez")

func test_take_piece_la_quita_de_las_disponibles_y_emite_senal(t) -> void:
	var source := InventoryPieceSource.new()
	var piece := InventoryPiece.new(&"p1", ShapeData.new(&"1x1", [Vector2i(0, 0)]))
	source.offer_piece(piece)
	var taken_events: Array = []
	source.piece_taken.connect(func(p): taken_events.append(p))

	var result: bool = source.take_piece(piece)

	t.assert_true(result, "tomar una pieza ofrecida debe devolver true")
	t.assert_eq(source.get_available_pieces().size(), 0, "la pieza tomada no debe seguir disponible")
	t.assert_eq(taken_events.size(), 1, "piece_taken debe emitirse exactamente una vez")

func test_take_piece_de_una_pieza_no_ofrecida_falla(t) -> void:
	var source := InventoryPieceSource.new()
	var piece := InventoryPiece.new(&"p1", ShapeData.new(&"1x1", [Vector2i(0, 0)]))

	var result: bool = source.take_piece(piece)

	t.assert_true(not result, "tomar una pieza que no está ofrecida debe fallar")

func test_return_piece_la_vuelve_a_ofrecer_y_emite_senal(t) -> void:
	var source := InventoryPieceSource.new()
	var piece := InventoryPiece.new(&"p1", ShapeData.new(&"1x1", [Vector2i(0, 0)]))
	source.offer_piece(piece)
	source.take_piece(piece)
	var returned_events: Array = []
	source.piece_returned.connect(func(p): returned_events.append(p))

	source.return_piece(piece)

	t.assert_eq(source.get_available_pieces().size(), 1, "la pieza devuelta debe volver a estar disponible")
	t.assert_eq(returned_events.size(), 1, "piece_returned debe emitirse exactamente una vez")
