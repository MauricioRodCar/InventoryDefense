class_name BattleView
extends Node2D
## Vista mínima de una CombatSimulation: refleja su estado creando/
## destruyendo representaciones visuales de Enemy/Defender en respuesta a sus
## señales, y actualiza el estado continuo (posición, vida) solo cuando
## BattleRunner lo pide explícitamente vía sync(), tras cada advance(delta).
## No conoce reglas de combate ni valida nada; solo observa y dibuja.
## CombatSimulation nunca conoce esta clase.

const CombatSimulation = preload("res://Scripts/Gameplay/Combat/combat_simulation.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const CombatPathView = preload("res://Scripts/UI/Battle/combat_path_view.gd")
const EnemyView = preload("res://Scripts/UI/Battle/enemy_view.gd")
const DefenderView = preload("res://Scripts/UI/Battle/defender_view.gd")

@export var path_start: Vector2 = Vector2(0, 0)
@export var path_end: Vector2 = Vector2(400, 0)
@export var defender_row_position: Vector2 = Vector2(0, 80)
@export var defender_spacing: float = 32.0

var _simulation: CombatSimulation
var _combat_path_view: CombatPathView
var _enemy_views: Dictionary = {} # Enemy -> EnemyView

## Punto de entrada único: entrega la simulación a observar y la longitud
## lógica del camino (necesaria para CombatPathView, ajena a CombatSimulation).
func set_combat_simulation(simulation: CombatSimulation, path_length: float) -> void:
	_disconnect_simulation()
	_clear_views()

	_simulation = simulation
	if _simulation == null:
		return

	_combat_path_view = CombatPathView.new(path_start, path_end, path_length)
	_simulation.enemy_spawned.connect(_on_enemy_spawned)
	_simulation.enemy_defeated.connect(_on_enemy_removed)
	_simulation.enemy_reached_end.connect(_on_enemy_removed)
	_render_initial_state()

func _exit_tree() -> void:
	_disconnect_simulation()

## Llamado explícitamente por BattleRunner tras cada simulation.advance(delta):
## empuja el estado continuo (posición derivada de path_progress, vida) que
## no tiene señal propia, porque moverse no es un evento de dominio.
func sync() -> void:
	if _simulation == null:
		return
	for enemy in _enemy_views:
		var view: EnemyView = _enemy_views[enemy]
		view.update_state(_combat_path_view.position_for(enemy.path_progress), _health_ratio(enemy))

func _render_initial_state() -> void:
	for enemy in _simulation.get_enemies():
		_add_enemy_view(enemy)
	for index in _simulation.get_defenders().size():
		_add_defender_view(index)

func _on_enemy_spawned(enemy: Enemy) -> void:
	_add_enemy_view(enemy)

func _on_enemy_removed(enemy: Enemy) -> void:
	var view: EnemyView = _enemy_views.get(enemy)
	if view == null:
		return
	_enemy_views.erase(enemy)
	view.queue_free()

func _add_enemy_view(enemy: Enemy) -> void:
	if _enemy_views.has(enemy):
		return
	var view := EnemyView.new()
	add_child(view)
	view.update_state(_combat_path_view.position_for(enemy.path_progress), _health_ratio(enemy))
	_enemy_views[enemy] = view

## Los Defender no llevan posición propia (ver notas de diseño de Battle en
## el README): esta iteración los distribuye en una fila por índice, sin
## relación con su celda original en el inventario.
func _add_defender_view(index: int) -> void:
	var view := DefenderView.new()
	add_child(view)
	view.setup(defender_row_position + Vector2(defender_spacing * index, 0))

func _health_ratio(enemy: Enemy) -> float:
	if enemy.max_health <= 0:
		return 0.0
	return float(enemy.current_health) / float(enemy.max_health)

func _clear_views() -> void:
	for view in _enemy_views.values():
		view.queue_free()
	_enemy_views.clear()
	for child in get_children():
		if child is DefenderView:
			child.queue_free()

func _disconnect_simulation() -> void:
	if _simulation == null:
		return
	if _simulation.enemy_spawned.is_connected(_on_enemy_spawned):
		_simulation.enemy_spawned.disconnect(_on_enemy_spawned)
	if _simulation.enemy_defeated.is_connected(_on_enemy_removed):
		_simulation.enemy_defeated.disconnect(_on_enemy_removed)
	if _simulation.enemy_reached_end.is_connected(_on_enemy_removed):
		_simulation.enemy_reached_end.disconnect(_on_enemy_removed)
