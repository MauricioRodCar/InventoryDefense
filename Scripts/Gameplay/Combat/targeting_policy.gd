class_name TargetingPolicy
extends RefCounted
## Algoritmo sin estado ni propiedad del dominio: decide qué enemigo vivo
## debería ser el objetivo de un ataque. Extraído de AttackPhase para que la
## regla de selección de objetivo tenga un punto único y testeable por
## separado, sin introducir todavía ninguna variedad de comportamiento: hoy
## existe una única política, compartida por todos los defensores. Una
## segunda política (y la composición por Defender/DefenderData que la
## acompañaría) solo debería aparecer cuando exista una necesidad real de que
## distintos defensores seleccionen objetivo de forma distinta.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")

## Devuelve el enemigo vivo con mayor path_progress (el más cercano a llegar
## al final del camino), o null si no hay ninguno vivo. Misma regla mínima
## que ya usaba AttackPhase: sin alcance ni posiciones todavía.
func select_target(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if best == null or enemy.path_progress > best.path_progress:
			best = enemy
	return best
