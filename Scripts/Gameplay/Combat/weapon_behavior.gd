class_name WeaponBehavior
extends RefCounted
## Contrato base para el patrón de ejecución de un ataque: qué impactos
## (objetivo + daño) produce un arma dado el objetivo prioritario que ya
## resolvió una TargetingPolicy. No se instancia directamente: cada
## WeaponData compone una subclase concreta (ver SingleShotWeaponBehavior).
## Al ser stateless, una misma instancia de una subclase puede compartirse
## entre varias WeaponData sin riesgo de interferencia, igual que ya ocurre
## con TargetingPolicy.
##
## AttackPhase delega siempre en weapon_data.weapon_behavior.resolve(), así
## que agregar un patrón de ataque nuevo (doble disparo, escopeta, área,
## cadena, perforación...) nunca requiere modificarla: basta con una
## subclase nueva.
##
## No decide a quién priorizar (eso es responsabilidad exclusiva de
## TargetingPolicy): recibe el objetivo prioritario ya resuelto y solo
## decide cómo se ejecuta el ataque alrededor de él.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")

## Un impacto resuelto: qué enemigo recibe cuánto daño. No es una mutación
## en sí, solo la intención calculada. No conoce Defender ni WeaponInstance:
## solo objetivo y daño.
class Hit:
	extends RefCounted
	var target: Enemy
	var damage: int

	func _init(p_target: Enemy, p_damage: int) -> void:
		target = p_target
		damage = p_damage

## Devuelve los impactos que produce el ataque dado el daño base del arma,
## el objetivo prioritario ya resuelto por TargetingPolicy y la lista
## completa de enemigos vivos (disponible para patrones que golpeen más de
## un objetivo). Las subclases concretas implementan el patrón real.
func resolve(damage: int, primary_target: Enemy, enemies: Array[Enemy]) -> Array[Hit]:
	return []
