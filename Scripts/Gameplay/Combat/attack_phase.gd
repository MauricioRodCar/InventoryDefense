class_name AttackPhase
extends RefCounted
## Algoritmo sin estado ni propiedad del dominio: decide qué defensores
## atacan, contra qué enemigo y con cuánto daño, sin mutar Enemy ni
## WeaponInstance directamente ni asumir la propiedad de las colecciones
## recibidas. CombatSimulation decide si aplica el resultado (daño y
## reinicio de cooldown) y es el único emisor de defender_attacked.
##
## Asume que el cooldown de cada WeaponInstance ya fue avanzado (tickeado)
## por CombatSimulation antes de llamar a advance(): esta fase solo lee
## is_ready(), nunca tickea el cooldown.
##
## La selección de objetivo no vive aquí: se delega en un TargetingPolicy
## propio, para que AttackPhase no crezca con cada regla de selección nueva.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const TargetingPolicy = preload("res://Scripts/Gameplay/Combat/targeting_policy.gd")

## Resultado de un ataque: qué defensor ataca a qué enemigo y con cuánto
## daño. No es una mutación en sí, solo la intención calculada.
class Result:
	extends RefCounted
	var defender: Defender
	var target: Enemy
	var damage: int

	func _init(p_defender: Defender, p_target: Enemy, p_damage: int) -> void:
		defender = p_defender
		target = p_target
		damage = p_damage

var _targeting_policy: TargetingPolicy

func _init() -> void:
	_targeting_policy = TargetingPolicy.new()

## Para cada defensor listo, ataca al objetivo que resuelva el TargetingPolicy.
func advance(defenders: Array[Defender], enemies: Array[Enemy]) -> Array[Result]:
	var results: Array[Result] = []
	for defender in defenders:
		if not defender.weapon_instance.is_ready():
			continue
		var target: Enemy = _targeting_policy.select_target(enemies)
		if target == null:
			continue
		results.append(Result.new(defender, target, defender.weapon_instance.weapon_data.damage))
	return results
