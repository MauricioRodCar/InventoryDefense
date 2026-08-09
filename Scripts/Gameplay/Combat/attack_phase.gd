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
##
## El sorteo de crítico tampoco vive en WeaponBehavior: es un eje ortogonal
## a cuántos impactos produce un ataque (ver notas de diseño de Combate en
## el README), así que se resuelve acá, una vez por Hit ya producido, usando
## weapon_data.crit_chance/crit_multiplier.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")

## Resultado de un ataque: qué defensor ataca a qué enemigo, con cuánto
## daño y si fue crítico. No es una mutación en sí, solo la intención
## calculada.
class Result:
	extends RefCounted
	var defender: Defender
	var target: Enemy
	var damage: int
	var is_critical: bool

	func _init(p_defender: Defender, p_target: Enemy, p_damage: int, p_is_critical: bool = false) -> void:
		defender = p_defender
		target = p_target
		damage = p_damage
		is_critical = p_is_critical

## Para cada defensor listo, resuelve el objetivo prioritario de su propia
## TargetingPolicy compuesta y delega en su WeaponBehavior compuesto qué
## impactos produce el ataque contra ese objetivo. Cada impacto sortea su
## propio crítico de forma independiente contra weapon_data.crit_chance
## (rng explícito, nunca randf() global, para que el resultado sea
## determinista y testeable headless). Sin rng indicado, crea uno efímero
## para esta llamada.
func advance(defenders: Array[Defender], enemies: Array[Enemy], rng: RandomNumberGenerator = null) -> Array[Result]:
	if rng == null:
		rng = RandomNumberGenerator.new()
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
			var is_critical := rng.randf() < weapon_data.crit_chance
			var final_damage := roundi(hit.damage * weapon_data.crit_multiplier) if is_critical else hit.damage
			results.append(Result.new(defender, hit.target, final_damage, is_critical))
	return results
