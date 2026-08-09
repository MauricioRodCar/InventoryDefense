class_name DoubleShotWeaponBehavior
extends WeaponBehavior
## Patrón de ataque de dos impactos: golpea dos veces al objetivo prioritario,
## cada impacto por el daño base del arma. Hit se hereda de WeaponBehavior:
## no se redeclara aquí.

func resolve(damage: int, primary_target: Enemy, enemies: Array[Enemy]) -> Array[Hit]:
	return [Hit.new(primary_target, damage), Hit.new(primary_target, damage)]
