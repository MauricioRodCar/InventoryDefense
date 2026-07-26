class_name BattleRunner
extends Node
## Ejecuta una batalla completa conectando los sistemas existentes: construye
## una CombatSimulation vía CombatSimulationBuilder (ya existente) y la
## avanza un frame a la vez. Única responsabilidad: el ciclo de vida
## temporal de una batalla (IDLE -> RUNNING -> FINISHED). No conoce reglas
## de combate ni de inventario, no traduce piezas y no dibuja nada.
##
## battle_view es la única vista que conoce: le entrega la simulación al
## arrancar y, tras cada advance(delta), le pide sincronizarse
## (battle_view.sync()). No relee ni reinterpreta las señales de
## CombatSimulation: esas fluyen directo de la simulación a battle_view.
##
## player_economy/enemy_reward_catalog son opcionales, mismo patrón que
## battle_view: si ambos están asignados, BattleRunner escucha
## enemy_defeated y acredita oro. No asume ninguna otra responsabilidad de
## progresión (sin BattleReward, sin recompensas de fin de oleada, etc.).

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const CombatSimulation = preload("res://Scripts/Gameplay/Combat/combat_simulation.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const CombatSimulationBuilder = preload("res://Scripts/Gameplay/Bridge/combat_simulation_builder.gd")
const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")
const EnemyRewardCatalog = preload("res://Scripts/Gameplay/Economy/enemy_reward_catalog.gd")

enum State { IDLE, RUNNING, FINISHED }

## Estado explícito del runner: evita que pausa, aceleración de tiempo o una
## futura fase de preparación tengan que inferirse indirectamente (p. ej. de
## si _simulation es null o si _process está activo).
signal state_changed(new_state: State)

var battle_view: BattleView
var player_economy: PlayerEconomy
var enemy_reward_catalog: EnemyRewardCatalog

var state: State = State.IDLE

var _simulation: CombatSimulation
var _builder: CombatSimulationBuilder = CombatSimulationBuilder.new()

func _ready() -> void:
	set_process(false)

## Construye la CombatSimulation a partir del estado actual de grid y de la
## configuración de la ronda, se la entrega a battle_view y arranca el
## bucle de advance(delta) por frame. No retiene grid/path/catalog/wave_data
## más allá de esta llamada, igual que CombatSimulationBuilder.build().
func start(grid: InventoryGrid, path: CombatPath, catalog: DefenderCatalog, wave_data: WaveData = null) -> void:
	_simulation = _builder.build(grid, path, catalog, wave_data)
	if battle_view != null:
		battle_view.set_combat_simulation(_simulation, path.length)
	if player_economy != null and enemy_reward_catalog != null:
		_simulation.enemy_defeated.connect(_on_enemy_defeated)
	_set_state(State.RUNNING)
	set_process(true)

func _process(delta: float) -> void:
	_simulation.advance(delta)
	if battle_view != null:
		battle_view.sync()
	if _simulation.is_battle_over():
		_finish()

func _finish() -> void:
	set_process(false)
	_set_state(State.FINISHED)

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)

## Acredita oro al derrotar un enemigo, consultando enemy_reward_catalog.
## Un enemigo sin recompensa configurada (get_gold_reward devuelve 0) no
## debe llamar a add_gold, que asume un amount positivo.
func _on_enemy_defeated(enemy: Enemy) -> void:
	var reward := enemy_reward_catalog.get_gold_reward(enemy.id)
	if reward > 0:
		player_economy.add_gold(reward)
