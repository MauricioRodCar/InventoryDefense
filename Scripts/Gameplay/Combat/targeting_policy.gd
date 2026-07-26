class_name TargetingPolicy
extends RefCounted
## Contrato base para las reglas de selección de objetivo: qué enemigo vivo
## debería atacar un Defender. No se instancia directamente: cada Defender
## compone una subclase concreta (ver HighestProgressTargetingPolicy,
## LowestHealthTargetingPolicy, LowestProgressTargetingPolicy). Al ser
## stateless, una misma instancia de una subclase puede compartirse entre
## varios Defender sin riesgo de interferencia, igual que ya ocurre con
## WeaponData.
##
## AttackPhase delega siempre en defender.targeting_policy.select_target(),
## así que agregar una regla de selección nueva nunca requiere modificarla:
## basta con una subclase nueva.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")

## Devuelve el enemigo vivo elegido como objetivo, o null si no hay ninguno
## vivo. Las subclases concretas implementan la regla real de selección.
func select_target(enemies: Array[Enemy]) -> Enemy:
	return null
