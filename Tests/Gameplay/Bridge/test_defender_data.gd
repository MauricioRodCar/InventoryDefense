extends RefCounted
## Tests básicos de DefenderData: definición pura, sin estado de ejecución.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")

func test_guarda_id_y_weapon_data(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 4, 1.0)
	var defender_data := DefenderData.new(&"knight", weapon_data)

	t.assert_eq(defender_data.id, &"knight", "debe guardar el id recibido")
	t.assert_eq(defender_data.weapon_data, weapon_data, "debe guardar el WeaponData recibido")
