extends RefCounted
## Tests básicos de DefenderTranslator: traduce una InventoryPiece en un
## Defender consultando un DefenderCatalog.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const DefenderTranslator = preload("res://Scripts/Gameplay/Bridge/defender_translator.gd")
const HighestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/highest_progress_targeting_policy.gd")
const LowestHealthTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_health_targeting_policy.gd")

func test_traduce_una_pieza_mapeada_en_un_defender(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 4, 1.0)
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", weapon_data), 1)])
	var piece := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))

	var defender := DefenderTranslator.new().translate(piece, catalog)

	t.assert_true(defender != null, "una pieza mapeada debe producir un Defender")
	t.assert_eq(defender.id, &"knight", "el Defender debe usar el id del DefenderData mapeado")
	t.assert_eq(defender.weapon_instance.weapon_data, weapon_data, "la WeaponInstance del Defender debe usar el WeaponData del DefenderData mapeado")

func test_una_pieza_sin_targeting_policy_explicita_produce_un_defender_con_el_default(t) -> void:
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0)), 1)])
	var piece := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))

	var defender := DefenderTranslator.new().translate(piece, catalog)

	t.assert_true(defender.targeting_policy is HighestProgressTargetingPolicy, "sin targeting_policy explícita en el DefenderData, el Defender debe conservar el default de HighestProgressTargetingPolicy")

func test_conserva_la_targeting_policy_explicita_del_defender_data(t) -> void:
	var policy := LowestHealthTargetingPolicy.new()
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"bar", DefenderData.new(&"finisher", WeaponData.new(&"dagger", 3, 0.5), policy), 1)])
	var piece := InventoryPiece.new(&"bar", ShapeData.new(&"3x1", [Vector2i(0, 0)]))

	var defender := DefenderTranslator.new().translate(piece, catalog)

	t.assert_eq(defender.targeting_policy, policy, "el Defender debe usar exactamente la TargetingPolicy compuesta en el DefenderData mapeado")

func test_dos_piezas_del_mismo_tipo_no_comparten_weapon_instance(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 4, 1.0)
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", weapon_data), 1)])
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

func test_una_pieza_de_rank_2_usa_la_entrada_de_rank_2_del_catalogo(t) -> void:
	var rank_1_data := DefenderData.new(&"knight_rank_1", WeaponData.new(&"sword", 4, 1.0))
	var rank_2_data := DefenderData.new(&"knight_rank_2", WeaponData.new(&"sword", 6, 1.0))
	var catalog := DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", rank_1_data, 1),
		DefenderCatalog.Entry.new(&"square", rank_2_data, 2),
	])
	var piece := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))
	piece.rank = 2

	var defender := DefenderTranslator.new().translate(piece, catalog)

	t.assert_eq(defender.id, &"knight_rank_2", "una pieza de rank 2 debe traducirse con la entrada de rank 2, no la de rank 1")
