class_name AreaWeaponBehavior
extends WeaponBehavior
## Patrón de ataque de área: golpea a todo enemigo vivo cuya distancia en
## path_progress al objetivo prioritario sea <= radius, cada impacto por el
## daño base del arma, sin falloff por distancia. El objetivo prioritario
## siempre queda incluido (su propia distancia a sí mismo es 0). Hit se
## hereda de WeaponBehavior: no se redeclara aquí.

var _radius: float

func _init(p_radius: float) -> void:
	_radius = p_radius

func resolve(damage: int, primary_target: Enemy, enemies: Array[Enemy]) -> Array[Hit]:
	var hits: Array[Hit] = []
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if absf(enemy.path_progress - primary_target.path_progress) <= _radius:
			hits.append(Hit.new(enemy, damage))
	return hits
