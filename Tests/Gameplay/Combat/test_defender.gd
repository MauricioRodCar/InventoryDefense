extends RefCounted
## Tests básicos de Defender: compone su capacidad ofensiva vía WeaponInstance.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")

func test_defender_expone_la_weapon_instance_compuesta(t) -> void:
	var weapon_instance := WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0))
	var defender := Defender.new(&"d1", weapon_instance)
	t.assert_eq(defender.id, &"d1", "Defender debe guardar el id indicado")
	t.assert_eq(defender.weapon_instance, weapon_instance, "Defender debe exponer la WeaponInstance que se le compuso")

func test_dos_defenders_pueden_compartir_el_mismo_weapon_data(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 5, 1.0)
	var defender_a := Defender.new(&"a", WeaponInstance.new(weapon_data))
	var defender_b := Defender.new(&"b", WeaponInstance.new(weapon_data))

	defender_a.weapon_instance._reset_cooldown()

	t.assert_true(not defender_a.weapon_instance.is_ready(), "el cooldown de a debe haberse activado")
	t.assert_true(defender_b.weapon_instance.is_ready(), "el cooldown de b no debe verse afectado por el de a: cada Defender tiene su propia WeaponInstance aunque compartan WeaponData")
