extends RefCounted
## Tests básicos de DefenderCatalog: mapeo de clave de tipo a DefenderData.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")

func test_devuelve_el_defender_data_asociado_a_una_clave(t) -> void:
	var knight_data := DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0))
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", knight_data)])

	t.assert_eq(catalog.get_defender_data(&"square"), knight_data, "debe devolver el DefenderData mapeado a esa clave")

func test_devuelve_null_si_la_clave_no_esta_mapeada(t) -> void:
	var catalog := DefenderCatalog.new()

	t.assert_true(catalog.get_defender_data(&"unmapped") == null, "una clave sin entrada debe devolver null")
