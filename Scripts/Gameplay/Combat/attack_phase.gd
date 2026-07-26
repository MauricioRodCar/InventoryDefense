class_name AttackPhase
extends RefCounted
## Algoritmo sin estado ni propiedad del dominio: decide qué defensores
## atacan y qué impactos produce cada ataque, sin mutar Enemy ni
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
## defender.targeting_policy.select_target(enemies) para obtener el
## objetivo prioritario. Cuántos impactos produce el ataque (y contra quién
## además del objetivo prioritario) tampoco vive aquí: eso lo decide
## weapon_data.weapon_behavior.resolve(), a quien se le entrega ese
## objetivo prioritario ya resuelto. AttackPhase únicamente coordina ambas
## estrategias y convierte cada WeaponBehavior.Hit en un Result. Así, ni
## una regla de targeting nueva ni un patrón de ataque nuevo requieren
## modificar esta clase.

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

## Para cada defensor listo, resuelve el objetivo prioritario de su propia
## TargetingPolicy compuesta y delega en su WeaponBehavior compuesto qué
## impactos produce el ataque contra ese objetivo.
func advance(defenders: Array[Defender], enemies: Array[Enemy]) -> Array[Result]:
	var results: Array[Result] = []
	for defender in defenders:
		if not defender.weapon_instance.is_ready():
			continue
		var primary_target: Enemy = defender.targeting_policy.select_target(enemies)
		if primary_target == null:
			continue
		var weapon_data := defender.weapon_instance.weapon_data
		var hits := weapon_data.weapon_behavior.resolve(weapon_data.damage, primary_target, enemies)
		for hit in hits:
			results.append(Result.new(defender, hit.target, hit.damage))
	return results
