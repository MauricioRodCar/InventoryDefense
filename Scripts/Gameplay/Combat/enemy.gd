class_name Enemy
extends RefCounted
## Instancia de un enemigo activo en la simulación: vida y progreso a lo
## largo del camino. No conoce CombatPath ni reglas de movimiento: solo
## expone su propio estado y los invariantes que le corresponden a él
## (vida acotada a [0, max_health], progreso nunca negativo). No emite
## señales: eso es responsabilidad de CombatSimulation (futuro).

const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")
const StatusEffectInstance = preload("res://Scripts/Gameplay/Combat/status_effect_instance.gd")

var id: StringName
var max_health: int
var current_health: int
var speed: float
var path_progress: float = 0.0
var status_effect_resistance: float = 0.0
var _active_status_effects: Array[StatusEffectInstance] = []

## Resultado de un tick de efecto de estado: qué efecto y cuánto daño hizo
## en ese tick. No es una entidad de dominio, solo el resultado pequeño de
## _tick_status_effects, mismo patrón que WeaponBehavior.Hit.
class StatusEffectTick:
	extends RefCounted
	var status_effect_id: StringName
	var damage: int
	func _init(p_status_effect_id: StringName, p_damage: int) -> void:
		status_effect_id = p_status_effect_id
		damage = p_damage

func _init(p_id: StringName, p_max_health: int, p_speed: float, p_status_effect_resistance: float = 0.0) -> void:
	id = p_id
	max_health = p_max_health
	current_health = p_max_health
	speed = p_speed
	status_effect_resistance = p_status_effect_resistance

func is_alive() -> bool:
	return current_health > 0

## Uso interno de AttackPhase: aplica daño sin dejar la vida fuera de [0, max_health].
func _take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)

## Uso interno de MovementPhase: avanza el progreso sin dejarlo negativo.
func _advance(delta_progress: float) -> void:
	path_progress = max(0.0, path_progress + delta_progress)

## Devuelve una copia de los efectos de estado activos (mismo patrón que
## InventoryGrid.get_pieces()), para que nadie fuera de Enemy pueda mutar el
## array interno. Uso futuro de la branch de visualización y de tests.
func get_active_status_effects() -> Array[StatusEffectInstance]:
	return _active_status_effects.duplicate()

## Uso interno de CombatSimulation (vía AttackPhase.Result.status_effect):
## resistencia >= 1.0 es inmunidad total, ni se trackea. Reaplicar el mismo
## id refresca la duración (remueve la instancia anterior antes de agregar
## la nueva) en vez de acumular una segunda instancia; efectos con id
## distinto coexisten.
func _apply_status_effect(data: StatusEffectData) -> void:
	if status_effect_resistance >= 1.0:
		return
	for existing in _active_status_effects:
		if existing.status_effect_data.id == data.id:
			_active_status_effects.erase(existing)
			break
	var damage_per_tick := roundi(data.damage_per_tick * (1.0 - status_effect_resistance))
	_active_status_effects.append(StatusEffectInstance.new(data, damage_per_tick))

## Uso interno de CombatSimulation: tickea cada efecto activo y devuelve un
## StatusEffectTick por cada uno que haya producido daño en este delta.
## Remueve del array los efectos que expiraron después de tickearlos (el
## último tick antes de expirar sigue contando).
func _tick_status_effects(delta: float) -> Array[StatusEffectTick]:
	var ticks: Array[StatusEffectTick] = []
	var expired: Array[StatusEffectInstance] = []
	for instance in _active_status_effects:
		var damage := instance._tick(delta)
		if damage > 0:
			ticks.append(StatusEffectTick.new(instance.status_effect_data.id, damage))
		if instance.is_expired():
			expired.append(instance)
	for instance in expired:
		_active_status_effects.erase(instance)
	return ticks
