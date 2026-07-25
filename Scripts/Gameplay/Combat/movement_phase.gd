class_name MovementPhase
extends RefCounted
## Algoritmo sin estado ni propiedad del dominio: calcula cuánto debería
## avanzar cada enemigo vivo en este tick, sin mutar Enemy directamente ni
## asumir la propiedad de la colección recibida. CombatSimulation decide si
## aplica el resultado (es quien realmente invoca Enemy._advance()).

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")

## Resultado de movimiento para un enemigo: cuánto debería avanzar su
## path_progress. No es una mutación en sí, solo la intención calculada.
class Result:
	extends RefCounted
	var enemy: Enemy
	var delta_progress: float

	func _init(p_enemy: Enemy, p_delta_progress: float) -> void:
		enemy = p_enemy
		delta_progress = p_delta_progress

## Calcula el avance de cada enemigo vivo según su velocidad. Los enemigos
## sin vida no producen resultado: no deberían seguir moviéndose.
func advance(enemies: Array[Enemy], delta: float) -> Array[Result]:
	var results: Array[Result] = []
	for enemy in enemies:
		if enemy.is_alive():
			results.append(Result.new(enemy, enemy.speed * delta))
	return results
