extends RefCounted
## Tests básicos de PieceDraftOption: ofrece una pieza nueva vía
## InventoryPieceSource al aplicarse.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")
const PieceDraftOption = preload("res://Scripts/Gameplay/Draft/piece_draft_option.gd")

func test_apply_ofrece_una_pieza_con_el_type_id_y_shape_correctos(t) -> void:
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	var option := PieceDraftOption.new(&"square", shape)
	var piece_source := InventoryPieceSource.new()

	option.apply(null, piece_source)

	var available := piece_source.get_available_pieces()
	t.assert_eq(available.size(), 1, "apply debe ofrecer exactamente una pieza")
	t.assert_eq(available[0].type_id, &"square", "la pieza ofrecida debe usar el type_id de la opción")
	t.assert_eq(available[0].shape, shape, "la pieza ofrecida debe usar el shape de la opción")

func test_describe_incluye_el_type_id(t) -> void:
	var option := PieceDraftOption.new(&"square", ShapeData.new(&"1x1", [Vector2i(0, 0)]))

	t.assert_eq(option.describe(), "Pieza: square", "describe debe incluir el type_id")
