class_name LowestHealthTargetingPolicy
extends TargetingPolicy
## Selecciona al enemigo vivo con menor current_health: prioriza asegurar
## bajas sobre enemigos ya debilitados, sin importar su avance en el camino.
## Enemy se hereda de TargetingPolicy: no se redeclara aquí.

func select_target(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if best == null or enemy.current_health < best.current_health:
			best = enemy
	return best
