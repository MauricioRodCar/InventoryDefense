class_name SingleShotWeaponBehavior
extends WeaponBehavior
## Patrón de ataque más simple: un único impacto sobre el objetivo
## prioritario, por el daño base del arma. Es el WeaponBehavior por defecto
## de WeaponData, para conservar sin cambios el comportamiento de cualquier
## arma que no indique un WeaponBehavior explícito. Hit se hereda de
## WeaponBehavior: no se redeclara aquí.

func resolve(damage: int, primary_target: Enemy, enemies: Array[Enemy]) -> Array[Hit]:
	return [Hit.new(primary_target, damage)]
