extends RefCounted
## Tests básicos de WeaponInstance: cooldown de un WeaponData en uso.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")

func test_una_instancia_nueva_esta_lista_para_atacar(t) -> void:
	var instance := WeaponInstance.new(WeaponData.new(&"sword", 5, 1.5))
	t.assert_true(instance.is_ready(), "una WeaponInstance recién creada debe estar lista para atacar")

func test_reset_cooldown_usa_el_intervalo_del_weapon_data(t) -> void:
	var instance := WeaponInstance.new(WeaponData.new(&"sword", 5, 1.5))
	instance._reset_cooldown()
	t.assert_eq(instance.cooldown_remaining, 1.5, "tras _reset_cooldown, cooldown_remaining debe igualar attack_interval")
	t.assert_true(not instance.is_ready(), "tras reiniciar el cooldown la instancia no debe estar lista")

func test_tick_reduce_el_cooldown_sin_bajar_de_cero(t) -> void:
	var instance := WeaponInstance.new(WeaponData.new(&"sword", 5, 2.0))
	instance._reset_cooldown()
	instance._tick(0.5)
	t.assert_eq(instance.cooldown_remaining, 1.5, "tick debe restar el delta del cooldown restante")
	instance._tick(10.0)
	t.assert_eq(instance.cooldown_remaining, 0.0, "el cooldown nunca debe quedar negativo")
	t.assert_true(instance.is_ready(), "cooldown en cero debe dejar la instancia lista para atacar")
