class_name CombatSimulationBuilder
extends RefCounted
## Construye una CombatSimulation lista para combate a partir del estado
## actual de un InventoryGrid: traduce cada InventoryPiece colocada en un
## Defender (vía DefenderTranslator) y los añade a una CombatSimulation
## nueva junto con el CombatPath y la Wave de la ronda. Es la única clase
## del bridge que conoce InventoryGrid y CombatSimulation a la vez; ninguna
## de las dos se entera de la existencia de la otra. No conoce UI ni retiene
## ninguna referencia entre llamadas a build().

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const Wave = preload("res://Scripts/Gameplay/Combat/wave.gd")
const CombatSimulation = preload("res://Scripts/Gameplay/Combat/combat_simulation.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const DefenderTranslator = preload("res://Scripts/Gameplay/Bridge/defender_translator.gd")

var _translator: DefenderTranslator

func _init() -> void:
	_translator = DefenderTranslator.new()

## Piezas del grid sin DefenderData asociado en el catálogo se ignoran: no
## producen Defender ni interrumpen la construcción del resto.
func build(grid: InventoryGrid, path: CombatPath, catalog: DefenderCatalog, wave_data: WaveData = null) -> CombatSimulation:
	var wave: Wave = Wave.new(wave_data) if wave_data != null else null
	var simulation := CombatSimulation.new(path, wave)
	for piece in grid.get_pieces():
		var defender := _translator.translate(piece, catalog)
		if defender != null:
			simulation.add_defender(defender)
	return simulation
