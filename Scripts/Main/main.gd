extends Node2D
## Composition root de la vertical slice de inventario + batalla + draft de
## fin de wave. Construye el InventoryGrid, una fuente de piezas de prueba,
## un _wave_schedule corto de prueba (en vez de una única WaveData) y un
## DraftPool de prueba, y conecta el dominio con las vistas
## (InventoryGridView, InventoryPieceSourceView, BattleView, GoldCounterView,
## DraftView) y los orquestadores de interacción
## (InventoryInteractionController, BattleRunner). No contiene lógica de
## juego propia: solo decide cuándo arranca cada wave, cuándo se ofrece un
## draft y cablea referencias.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")
const InventoryPieceSourceSandbox = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source_sandbox.gd")
const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")
const AreaWeaponBehavior = preload("res://Scripts/Gameplay/Combat/area_weapon_behavior.gd")
const HighestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/highest_progress_targeting_policy.gd")
const LowestHealthTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_health_targeting_policy.gd")
const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")
const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")
const EnemyRewardCatalog = preload("res://Scripts/Gameplay/Economy/enemy_reward_catalog.gd")
const DraftPool = preload("res://Scripts/Gameplay/Draft/draft_pool.gd")
const DraftOption = preload("res://Scripts/Gameplay/Draft/draft_option.gd")
const PieceDraftOption = preload("res://Scripts/Gameplay/Draft/piece_draft_option.gd")
const GridExpansionDraftOption = preload("res://Scripts/Gameplay/Draft/grid_expansion_draft_option.gd")
const Draft = preload("res://Scripts/Gameplay/Draft/draft.gd")

const REROLL_COST := 5

@onready var _grid_view: InventoryGridView = $InventoryGridView
@onready var _source_view: InventoryPieceSourceView = $InventoryPieceSourceView
@onready var _interaction_controller: InventoryInteractionController = $InventoryInteractionController
@onready var _battle_runner: BattleRunner = $BattleRunner
@onready var _battle_view: BattleView = $BattleView
@onready var _gold_counter_view: GoldCounterView = $GoldCounterView
@onready var _draft_view: DraftView = $DraftView

var _grid: InventoryGrid
var _piece_source: InventoryPieceSource
var _combat_path: CombatPath
var _defender_catalog: DefenderCatalog
var _wave_schedule: Array[WaveData]
var _current_wave_index: int = 0
var _player_economy: PlayerEconomy
var _enemy_reward_catalog: EnemyRewardCatalog
var _draft_pool: DraftPool
var _rng: RandomNumberGenerator
var _draft: Draft
var _ready_for_next_wave: bool = true
var _all_waves_finished: bool = false

func _ready() -> void:
	_grid = InventoryGrid.new(6, 6)
	_piece_source = InventoryPieceSourceSandbox.new()

	_grid_view.set_inventory_grid(_grid)
	_source_view.set_piece_source(_piece_source)

	_interaction_controller.grid_view = _grid_view
	_interaction_controller.source_view = _source_view
	_interaction_controller.set_inventory_grid(_grid)
	_interaction_controller.set_piece_source(_piece_source)

	_combat_path = CombatPath.new(400.0)
	_defender_catalog = _build_sandbox_defender_catalog()
	_wave_schedule = LevelSelection.selected_wave_schedule if not LevelSelection.selected_wave_schedule.is_empty() else _build_sandbox_wave_schedule()
	_player_economy = PlayerEconomy.new()
	_enemy_reward_catalog = _build_sandbox_enemy_reward_catalog()
	_draft_pool = _build_sandbox_draft_pool()
	_rng = RandomNumberGenerator.new()

	_battle_runner.battle_view = _battle_view
	_battle_runner.player_economy = _player_economy
	_battle_runner.enemy_reward_catalog = _enemy_reward_catalog
	_battle_runner.state_changed.connect(_on_battle_runner_state_changed)

	_gold_counter_view.set_player_economy(_player_economy)

	_draft_view.option_selected.connect(_on_draft_option_selected)
	_draft_view.reroll_requested.connect(_on_draft_reroll_requested)

## Disparador temporal de "Start Battle" para esta vertical slice (sin UI
## definitiva todavía): pulsar aceptar arranca la wave actual del schedule,
## solo si no hay una batalla en curso ni un draft pendiente de resolver
## (_ready_for_next_wave reemplaza por completo la consulta anterior a
## _battle_runner.state, porque BattleRunner.start() no tiene ningún guard de
## estado propio) y si todavía queda alguna wave en el schedule.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _ready_for_next_wave and _current_wave_index < _wave_schedule.size():
		_ready_for_next_wave = false
		_battle_runner.start(_grid, _combat_path, _defender_catalog, _wave_schedule[_current_wave_index])
	if event.is_action_pressed("ui_cancel") and _all_waves_finished:
		get_tree().change_scene_to_file("res://scenes/overworld/Overworld.tscn")

## Reacciona únicamente a la transición a FINISHED: avanza el índice de wave
## y, si todavía queda alguna wave siguiente, arma un draft nuevo y lo entrega
## a _draft_view. Si el schedule ya se agotó, la demo de sandbox termina ahí
## sin más waves ni draft — esperado, no es un bug.
func _on_battle_runner_state_changed(new_state: BattleRunner.State) -> void:
	if new_state != BattleRunner.State.FINISHED:
		return
	_current_wave_index += 1
	if _current_wave_index >= _wave_schedule.size():
		_all_waves_finished = true
		return
	_draft = Draft.new(_draft_pool, _rng, REROLL_COST)
	_draft.option_chosen.connect(_on_draft_option_chosen)
	_draft_view.set_draft(_draft, _player_economy)

## _draft_view ya se oculta a sí misma al recibir esta misma señal; main.gd
## no la vuelve a esconder, solo reacciona a nivel de composition root
## habilitando la siguiente wave.
func _on_draft_option_chosen(_option: DraftOption) -> void:
	_draft = null
	_ready_for_next_wave = true

func _on_draft_option_selected(index: int) -> void:
	if _draft == null:
		return
	_draft.choose(index, _grid, _piece_source)

func _on_draft_reroll_requested() -> void:
	if _draft == null:
		return
	_draft.reroll(_player_economy)

## Catálogo de prueba para esta vertical slice: un DefenderData por cada tipo
## de InventoryPiece que ofrece InventoryPieceSourceSandbox, cada uno un
## arquetipo distinto compuesto únicamente a partir de WeaponData/
## WeaponBehavior/TargetingPolicy ya existentes (ninguna subclase nueva de
## Defender ni DefenderData): square → Vanguardia (HighestProgress +
## SingleShot, daño alto y cadencia lenta, aplica quemadura), bar →
## Rematador (LowestHealth + SingleShot, daño medio y cadencia rápida,
## aplica veneno), corner → Artillero (HighestProgress + Area, mismo daño
## base por impacto repartido entre todos los enemigos cercanos al objetivo
## prioritario, sin efecto de estado — combinar área y efecto de estado en el
## mismo arquetipo dificultaría distinguir visualmente cuál está pasando, ver
## roadmap de efectos de estado). A reemplazar cuando exista una fuente real
## de configuración de ronda.
##
## Cada arquetipo tiene una entrada por rank (1 a InventoryPiece.MAX_RANK):
## fusionar una pieza (ver notas de fusión en Inventario) sube su rank y hace
## que produzca un Defender más fuerte en la próxima batalla. Cadencia,
## WeaponBehavior, TargetingPolicy y status_effect se mantienen iguales entre
## ranks del mismo arquetipo, solo el daño escala a mano por rank (valores de
## sandbox, no una curva de balance final).
func _build_sandbox_defender_catalog() -> DefenderCatalog:
	var burn := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var poison := StatusEffectData.new(&"poison", 2, 1.0, 6.0)
	return DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", DefenderData.new(&"vanguard_defender", WeaponData.new(&"vanguard_weapon", 8, 2.0, SingleShotWeaponBehavior.new(), 0.2, 2.0, burn), HighestProgressTargetingPolicy.new()), 1),
		DefenderCatalog.Entry.new(&"square", DefenderData.new(&"vanguard_defender", WeaponData.new(&"vanguard_weapon", 12, 2.0, SingleShotWeaponBehavior.new(), 0.2, 2.0, burn), HighestProgressTargetingPolicy.new()), 2),
		DefenderCatalog.Entry.new(&"square", DefenderData.new(&"vanguard_defender", WeaponData.new(&"vanguard_weapon", 18, 2.0, SingleShotWeaponBehavior.new(), 0.2, 2.0, burn), HighestProgressTargetingPolicy.new()), 3),
		DefenderCatalog.Entry.new(&"bar", DefenderData.new(&"finisher_defender", WeaponData.new(&"finisher_weapon", 4, 0.5, SingleShotWeaponBehavior.new(), 0.2, 2.0, poison), LowestHealthTargetingPolicy.new()), 1),
		DefenderCatalog.Entry.new(&"bar", DefenderData.new(&"finisher_defender", WeaponData.new(&"finisher_weapon", 6, 0.5, SingleShotWeaponBehavior.new(), 0.2, 2.0, poison), LowestHealthTargetingPolicy.new()), 2),
		DefenderCatalog.Entry.new(&"bar", DefenderData.new(&"finisher_defender", WeaponData.new(&"finisher_weapon", 9, 0.5, SingleShotWeaponBehavior.new(), 0.2, 2.0, poison), LowestHealthTargetingPolicy.new()), 3),
		DefenderCatalog.Entry.new(&"corner", DefenderData.new(&"artillery_defender", WeaponData.new(&"artillery_weapon", 2, 1.0, AreaWeaponBehavior.new(60.0), 0.2, 2.0), HighestProgressTargetingPolicy.new()), 1),
		DefenderCatalog.Entry.new(&"corner", DefenderData.new(&"artillery_defender", WeaponData.new(&"artillery_weapon", 3, 1.0, AreaWeaponBehavior.new(60.0), 0.2, 2.0), HighestProgressTargetingPolicy.new()), 2),
		DefenderCatalog.Entry.new(&"corner", DefenderData.new(&"artillery_defender", WeaponData.new(&"artillery_weapon", 5, 1.0, AreaWeaponBehavior.new(60.0), 0.2, 2.0), HighestProgressTargetingPolicy.new()), 3),
	])

## Calendario de prueba: dos waves cortas de goblins (2 y 3 respectivamente),
## suficiente para demostrar el loop mínimo de sandbox (terminar una wave,
## resolver un draft, arrancar la siguiente) sin necesitar una curva de
## dificultad real, que sigue fuera de alcance.
func _build_sandbox_wave_schedule() -> Array[WaveData]:
	var goblin := EnemyData.new(&"goblin", 60, 20.0)
	var first_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
	])
	var second_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
	])
	return [first_wave, second_wave]

## Catálogo de prueba: recompensa en oro por cada tipo de enemigo de las
## WaveData de sandbox. A reemplazar cuando exista una fuente real de
## configuración de ronda.
func _build_sandbox_enemy_reward_catalog() -> EnemyRewardCatalog:
	return EnemyRewardCatalog.new([
		EnemyRewardCatalog.Entry.new(&"goblin", 5),
	])

## Pool de prueba para esta vertical slice: mismos 3 tipos de pieza que ya
## ofrece InventoryPieceSourceSandbox (mismos type_id/ShapeData literales) a
## peso 5.0 cada uno, más dos expansiones de grid a peso 1.0 cada una —
## proporción ~5:1 piezas:expansión, la "probabilidad menor" de expansión
## definida en el objetivo de producto. A reemplazar cuando exista una
## fuente real de configuración de ronda.
func _build_sandbox_draft_pool() -> DraftPool:
	return DraftPool.new([
		DraftPool.Entry.new(PieceDraftOption.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])), 5.0),
		DraftPool.Entry.new(PieceDraftOption.new(&"bar", ShapeData.new(&"3x1", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])), 5.0),
		DraftPool.Entry.new(PieceDraftOption.new(&"corner", ShapeData.new(&"corner", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)])), 5.0),
		DraftPool.Entry.new(GridExpansionDraftOption.new(1, 0), 1.0),
		DraftPool.Entry.new(GridExpansionDraftOption.new(0, 1), 1.0),
	])
