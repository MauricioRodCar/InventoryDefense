extends Node2D
## Composition root de la vertical slice de inventario + batalla. Construye
## el InventoryGrid, una fuente de piezas de prueba y la configuración de
## ronda de prueba, y conecta el dominio con las vistas (InventoryGridView,
## InventoryPieceSourceView, BattleView) y los orquestadores de interacción
## (InventoryInteractionController, BattleRunner). No contiene lógica de
## juego propia: solo decide cuándo arranca la batalla y cablea referencias.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPieceSourceSandbox = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source_sandbox.gd")
const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")

@onready var _grid_view: InventoryGridView = $InventoryGridView
@onready var _source_view: InventoryPieceSourceView = $InventoryPieceSourceView
@onready var _interaction_controller: InventoryInteractionController = $InventoryInteractionController
@onready var _battle_runner: BattleRunner = $BattleRunner
@onready var _battle_view: BattleView = $BattleView

var _grid: InventoryGrid
var _combat_path: CombatPath
var _defender_catalog: DefenderCatalog
var _wave_data: WaveData

func _ready() -> void:
	_grid = InventoryGrid.new(6, 6)
	var piece_source := InventoryPieceSourceSandbox.new()

	_grid_view.set_inventory_grid(_grid)
	_source_view.set_piece_source(piece_source)

	_interaction_controller.grid_view = _grid_view
	_interaction_controller.source_view = _source_view
	_interaction_controller.set_inventory_grid(_grid)
	_interaction_controller.set_piece_source(piece_source)

	_combat_path = CombatPath.new(400.0)
	_defender_catalog = _build_sandbox_defender_catalog()
	_wave_data = _build_sandbox_wave_data()

	_battle_runner.battle_view = _battle_view

## Disparador temporal de "Start Battle" para esta vertical slice (sin UI
## definitiva todavía): pulsar aceptar arranca la única batalla posible una
## vez, mientras el runner siga en IDLE.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _battle_runner.state == BattleRunner.State.IDLE:
		_battle_runner.start(_grid, _combat_path, _defender_catalog, _wave_data)

## Catálogo de prueba para esta vertical slice: un DefenderData por cada tipo
## de InventoryPiece que ofrece InventoryPieceSourceSandbox. A reemplazar
## cuando exista una fuente real de configuración de ronda.
func _build_sandbox_defender_catalog() -> DefenderCatalog:
	return DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", DefenderData.new(&"square_defender", WeaponData.new(&"square_weapon", 2, 1.0))),
		DefenderCatalog.Entry.new(&"bar", DefenderData.new(&"bar_defender", WeaponData.new(&"bar_weapon", 3, 1.5))),
		DefenderCatalog.Entry.new(&"corner", DefenderData.new(&"corner_defender", WeaponData.new(&"corner_weapon", 1, 0.5))),
	])

## Calendario de prueba: tres goblins espaciados en el tiempo, suficiente
## para observar una batalla completa de principio a fin.
func _build_sandbox_wave_data() -> WaveData:
	var goblin := EnemyData.new(&"goblin", 10, 20.0)
	return WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
	])
