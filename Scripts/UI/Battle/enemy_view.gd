class_name EnemyView
extends Node2D
## Representación visual mínima de un Enemy activo: un círculo cuya posición
## y color reflejan el estado que BattleView le empuja explícitamente. No
## lee el dominio por sí misma ni tiene _process propio: BattleView es quien
## decide cuándo y con qué datos actualizarla (ver BattleView.sync()).

const _RADIUS: float = 10.0

## Color por efecto de estado, resuelto acá y no en el dominio: mismo
## criterio que InventoryPiece.type_id (el dominio expone un id, la vista
## mapea ese id a un color localmente). StatusEffectData no lleva ningún
## campo de color.
const _COLOR_BY_STATUS_EFFECT_ID: Dictionary[StringName, Color] = {
	&"burn": Color.ORANGE,
	&"poison": Color.PURPLE,
}

var _health_ratio: float = 1.0
var _active_status_effect_ids: Array[StringName] = []

## Único punto de entrada de estado: BattleView ya resolvió la posición de
## mundo (vía CombatPathView), el ratio de vida y los ids de efectos de
## estado activos antes de llamar aquí.
func update_state(world_position: Vector2, health_ratio: float, active_status_effect_ids: Array[StringName] = []) -> void:
	position = world_position
	_health_ratio = clampf(health_ratio, 0.0, 1.0)
	_active_status_effect_ids = active_status_effect_ids
	queue_redraw()

## Placeholder simple: si hay varios efectos activos a la vez, se mezcla el
## color del primero de la lista que tenga entrada en
## _COLOR_BY_STATUS_EFFECT_ID, no una combinación de todos — suficiente para
## esta iteración (ver roadmap de efectos de estado, sección Branch 2, sobre
## por qué Artillero se quedó sin efecto de estado para no tener que resolver
## esto con más de uno a la vez sobre el mismo enemigo).
func _draw() -> void:
	var color := Color.RED.lerp(Color.BLACK, 1.0 - _health_ratio)
	for status_effect_id in _active_status_effect_ids:
		if _COLOR_BY_STATUS_EFFECT_ID.has(status_effect_id):
			color = color.lerp(_COLOR_BY_STATUS_EFFECT_ID[status_effect_id], 0.5)
			break
	draw_circle(Vector2.ZERO, _RADIUS, color)
