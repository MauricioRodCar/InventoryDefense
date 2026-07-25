extends RefCounted
## Tests básicos de DefenderTranslator: traduce una InventoryPiece en un
## Defender consultando un DefenderCatalog.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const DefenderTranslator = preload("res://Scripts/Gameplay/Bridge/defender_translator.gd")

func test_traduce_una_pieza_mapeada_en_un_defender(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 4, 1.0)
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", weapon_data))])
	var piece := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))

	var defender := DefenderTranslator.new().translate(piece, catalog)

	t.assert_true(defender != null, "una pieza mapeada debe producir un Defender")
	t.assert_eq(defender.id, &"knight", "el Defender debe usar el id del DefenderData mapeado")
	t.assert_eq(defender.weapon_instance.weapon_data, weapon_data, "la WeaponInstance del Defender debe usar el WeaponData del DefenderData mapeado")

func test_dos_piezas_del_mismo_tipo_no_comparten_weapon_instance(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 4, 1.0)
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", weapon_data))])
	var translator := DefenderTranslator.new()
	var piece_a := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))
	var piece_b := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))

	var defender_a := translator.translate(piece_a, catalog)
	var defender_b := translator.translate(piece_b, catalog)

	t.assert_true(defender_a.weapon_instance != defender_b.weapon_instance, "cada Defender traducido debe tener su propia WeaponInstance, aunque compartan WeaponData")

func test_una_pieza_sin_mapeo_devuelve_null(t) -> void:
	var catalog := DefenderCatalog.new()
	var piece := InventoryPiece.new(&"unmapped", ShapeData.new(&"1x1", [Vector2i(0, 0)]))

	var defender := DefenderTranslator.new().translate(piece, catalog)

	t.assert_true(defender == null, "una pieza sin DefenderData asociado no debe producir un Defender")
