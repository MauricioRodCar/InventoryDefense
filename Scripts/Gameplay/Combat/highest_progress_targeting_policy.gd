class_name HighestProgressTargetingPolicy
extends TargetingPolicy
## Selecciona al enemigo vivo con mayor path_progress: el más cercano a
## llegar al final del camino. Regla original de TargetingPolicy, movida
## aquí sin cambios de comportamiento al convertir TargetingPolicy en
## contrato base. Enemy se hereda de TargetingPolicy: no se redeclara aquí.

func select_target(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if best == null or enemy.path_progress > best.path_progress:
			best = enemy
	return best
