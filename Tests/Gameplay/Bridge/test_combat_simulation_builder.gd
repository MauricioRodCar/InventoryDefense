extends RefCounted
## Tests básicos de CombatSimulationBuilder: construye una CombatSimulation
## lista a partir del estado actual de un InventoryGrid.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const CombatSimulationBuilder = preload("res://Scripts/Gameplay/Bridge/combat_simulation_builder.gd")

func test_convierte_cada_pieza_colocada_mapeada_en_un_defender(t) -> void:
	var grid := InventoryGrid.new(4, 4)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	grid.place_piece(InventoryPiece.new(&"square", shape), Vector2i(0, 0))
	grid.place_piece(InventoryPiece.new(&"bar", shape), Vector2i(1, 0))
	var catalog := DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0)), 1),
		DefenderCatalog.Entry.new(&"bar", DefenderData.new(&"archer", WeaponData.new(&"bow", 2, 0.5)), 1),
	])

	var simulation := CombatSimulationBuilder.new().build(grid, CombatPath.new(100.0), catalog)

	t.assert_eq(simulation.get_defenders().size(), 2, "debe crear un Defender por cada pieza colocada mapeada en el catálogo")

func test_piezas_sin_mapeo_no_producen_defender(t) -> void:
	var grid := InventoryGrid.new(4, 4)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	grid.place_piece(InventoryPiece.new(&"unmapped", shape), Vector2i(0, 0))

	var simulation := CombatSimulationBuilder.new().build(grid, CombatPath.new(100.0), DefenderCatalog.new())

	t.assert_eq(simulation.get_defenders().size(), 0, "una pieza sin DefenderData asociado no debe agregar ningún Defender")

func test_sin_wave_data_no_configura_wave(t) -> void:
	var grid := InventoryGrid.new(2, 2)

	var simulation := CombatSimulationBuilder.new().build(grid, CombatPath.new(100.0), DefenderCatalog.new())
	simulation.advance(1.0)

	t.assert_eq(simulation.get_enemies().size(), 0, "sin wave_data, la CombatSimulation construida no debe poblar enemigos por sí sola")

func test_dos_piezas_del_mismo_type_id_producen_un_defender_cada_una(t) -> void:
	var grid := InventoryGrid.new(4, 4)
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	grid.place_piece(InventoryPiece.new(&"square", shape), Vector2i(0, 0))
	grid.place_piece(InventoryPiece.new(&"square", shape), Vector2i(1, 0))
	var catalog := DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0)), 1),
	])

	var simulation := CombatSimulationBuilder.new().build(grid, CombatPath.new(100.0), catalog)

	t.assert_eq(simulation.get_defenders().size(), 2, "dos piezas del mismo type_id deben producir un Defender cada una, no que la segunda desaparezca")
