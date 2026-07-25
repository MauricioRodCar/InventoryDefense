extends RefCounted
## Tests básicos de WeaponData: definición pura de daño y cadencia de ataque.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")

func test_guarda_los_valores_indicados(t) -> void:
	var weapon := WeaponData.new(&"sword", 5, 1.5)
	t.assert_eq(weapon.id, &"sword", "WeaponData debe guardar el id indicado")
	t.assert_eq(weapon.damage, 5, "WeaponData debe guardar el daño indicado")
	t.assert_eq(weapon.attack_interval, 1.5, "WeaponData debe guardar el intervalo de ataque indicado")
