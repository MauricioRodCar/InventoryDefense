class_name CombatPathMarkersView
extends Node2D
## Marcador visual fijo de los extremos del camino de combate: un círculo
## verde en el punto de spawn y uno rojo en el punto de llegada. No conoce
## CombatPath ni CombatPathView: BattleView ya tiene path_start/path_end
## resueltos como posiciones de mundo, no hace falta volver a calcular nada.

const _RADIUS: float = 8.0

var _spawn_position: Vector2
var _goal_position: Vector2

func setup(spawn_position: Vector2, goal_position: Vector2) -> void:
	_spawn_position = spawn_position
	_goal_position = goal_position
	queue_redraw()

func _draw() -> void:
	draw_circle(_spawn_position, _RADIUS, Color.GREEN)
	draw_circle(_goal_position, _RADIUS, Color.RED)
