class_name Enemy
extends RefCounted
## Instancia de un enemigo activo en la simulación: vida y progreso a lo
## largo del camino. No conoce CombatPath ni reglas de movimiento: solo
## expone su propio estado y los invariantes que le corresponden a él
## (vida acotada a [0, max_health], progreso nunca negativo). No emite
## señales: eso es responsabilidad de CombatSimulation (futuro).

var id: StringName
var max_health: int
var current_health: int
var speed: float
var path_progress: float = 0.0

func _init(p_id: StringName, p_max_health: int, p_speed: float) -> void:
	id = p_id
	max_health = p_max_health
	current_health = p_max_health
	speed = p_speed

func is_alive() -> bool:
	return current_health > 0

## Uso interno de AttackPhase: aplica daño sin dejar la vida fuera de [0, max_health].
func _take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)

## Uso interno de MovementPhase: avanza el progreso sin dejarlo negativo.
func _advance(delta_progress: float) -> void:
	path_progress = max(0.0, path_progress + delta_progress)
