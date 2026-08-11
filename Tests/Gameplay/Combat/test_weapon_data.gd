extends RefCounted
## Tests básicos de WeaponData: definición pura de daño, cadencia de ataque,
## patrón de impactos (weapon_behavior) y efecto de estado que aplica al
## impactar (status_effect).

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")
const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")

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

func test_sin_indicar_crit_queda_en_los_valores_por_defecto(t) -> void:
	var weapon := WeaponData.new(&"sword", 5, 1.5)
	t.assert_eq(weapon.crit_chance, 0.0, "sin indicar crit_chance, WeaponData debe defaultear a 0.0 (nunca crítico)")
	t.assert_eq(weapon.crit_multiplier, 2.0, "sin indicar crit_multiplier, WeaponData debe defaultear a 2.0")

func test_guarda_crit_chance_y_crit_multiplier_indicados_explicitamente(t) -> void:
	var weapon := WeaponData.new(&"sword", 5, 1.5, SingleShotWeaponBehavior.new(), 0.3, 1.5)
	t.assert_eq(weapon.crit_chance, 0.3, "WeaponData debe guardar el crit_chance indicado")
	t.assert_eq(weapon.crit_multiplier, 1.5, "WeaponData debe guardar el crit_multiplier indicado")

func test_sin_indicar_status_effect_queda_en_null(t) -> void:
	var weapon := WeaponData.new(&"sword", 5, 1.5)
	t.assert_true(weapon.status_effect == null, "sin indicar status_effect, WeaponData debe defaultear a null")

func test_guarda_status_effect_indicado_explicitamente(t) -> void:
	var status_effect := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var weapon := WeaponData.new(&"sword", 5, 1.5, SingleShotWeaponBehavior.new(), 0.0, 2.0, status_effect)
	t.assert_eq(weapon.status_effect, status_effect, "WeaponData debe exponer el StatusEffectData que se le indicó explícitamente")
