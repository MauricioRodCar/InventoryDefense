class_name LowestProgressTargetingPolicy
extends TargetingPolicy
## Selecciona al enemigo vivo con menor path_progress: el más cercano al
## inicio del camino, para control temprano en vez de contener al enemigo
## más avanzado. Enemy se hereda de TargetingPolicy: no se redeclara aquí.

func select_target(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if best == null or enemy.path_progress < best.path_progress:
			best = enemy
	return best
