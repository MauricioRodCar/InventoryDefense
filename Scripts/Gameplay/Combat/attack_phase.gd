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
## La selección de objetivo no vive aquí: cada Defender compone su propia
## TargetingPolicy, y AttackPhase únicamente delega en
## defender.targeting_policy.select_target(enemies). Así, una regla de
## selección nueva (o un arquetipo que reutilice una existente) nunca
## requiere modificar esta clase.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")

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

## Para cada defensor listo, ataca al objetivo que resuelva su propia
## TargetingPolicy compuesta.
func advance(defenders: Array[Defender], enemies: Array[Enemy]) -> Array[Result]:
	var results: Array[Result] = []
	for defender in defenders:
		if not defender.weapon_instance.is_ready():
			continue
		var target: Enemy = defender.targeting_policy.select_target(enemies)
		if target == null:
			continue
		results.append(Result.new(defender, target, defender.weapon_instance.weapon_data.damage))
	return results
