class_name EnemyView
extends Node2D
## Representación visual mínima de un Enemy activo: un círculo cuya posición
## y color reflejan el estado que BattleView le empuja explícitamente. No
## lee el dominio por sí misma ni tiene _process propio: BattleView es quien
## decide cuándo y con qué datos actualizarla (ver BattleView.sync()).

const _RADIUS: float = 10.0

var _health_ratio: float = 1.0

## Único punto de entrada de estado: BattleView ya resolvió la posición de
## mundo (vía CombatPathView) y el ratio de vida antes de llamar aquí.
func update_state(world_position: Vector2, health_ratio: float) -> void:
	position = world_position
	_health_ratio = clampf(health_ratio, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var color := Color.RED.lerp(Color.BLACK, 1.0 - _health_ratio)
	draw_circle(Vector2.ZERO, _RADIUS, color)
