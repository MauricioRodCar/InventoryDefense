class_name ProjectileView
extends Node2D
## Representación visual mínima de un impacto de ataque: un punto que viaja
## en línea recta desde el defensor atacante hasta el enemigo objetivo y se
## autodestruye al llegar. Pura ambientación de presentación, sin ningún
## dato de dominio que deba mantenerse en lockstep con CombatSimulation (ver
## notas de diseño de Battle en el README) — por eso, a diferencia del resto
## de las vistas de Battle, sí maneja su propio Tween.

const _RADIUS: float = 4.0
const _CRITICAL_RADIUS: float = 8.0
const _DURATION: float = 0.2

var _is_critical: bool = false

## No conoce Defender ni Enemy: BattleView ya resolvió ambas posiciones de
## mundo antes de llamar aquí. is_critical solo cambia cómo se dibuja el
## proyectil (ver _draw()), nunca su trayectoria ni duración.
func setup(from: Vector2, to: Vector2, is_critical: bool = false) -> void:
	position = from
	_is_critical = is_critical
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "position", to, _DURATION)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if _is_critical:
		draw_circle(Vector2.ZERO, _CRITICAL_RADIUS, Color.ORANGE)
	else:
		draw_circle(Vector2.ZERO, _RADIUS, Color.WHITE)
