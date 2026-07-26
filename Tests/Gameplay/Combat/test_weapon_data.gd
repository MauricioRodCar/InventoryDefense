extends RefCounted
## Tests básicos de WeaponData: definición pura de daño, cadencia de ataque
## y patrón de impactos (weapon_behavior).

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")

func test_guarda_los_valores_indicados(t) -> void:
	var weapon := WeaponData.new(&"sword", 5, 1.5)
	t.assert_eq(weapon.id, &"sword", "WeaponData debe guardar el id indicado")
	t.assert_eq(weapon.damage, 5, "WeaponData debe guardar el daño indicado")
	t.assert_eq(weapon.attack_interval, 1.5, "WeaponData debe guardar el intervalo de ataque indicado")

func test_compone_single_shot_weapon_behavior_por_defecto(t) -> void:
	var weapon := WeaponData.new(&"sword", 5, 1.5)
	t.assert_true(weapon.weapon_behavior is SingleShotWeaponBehavior, "WeaponData sin weapon_behavior explícito debe defaultear a SingleShotWeaponBehavior")

func test_compone_el_weapon_behavior_indicado_explicitamente(t) -> void:
	var behavior := SingleShotWeaponBehavior.new()
	var weapon := WeaponData.new(&"sword", 5, 1.5, behavior)
	t.assert_eq(weapon.weapon_behavior, behavior, "WeaponData debe exponer el WeaponBehavior que se le compuso explícitamente")
