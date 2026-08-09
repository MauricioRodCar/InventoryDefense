extends RefCounted
## Tests básicos de DefenderCatalog: mapeo de clave de tipo a DefenderData.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")

func test_devuelve_el_defender_data_asociado_a_una_clave(t) -> void:
	var knight_data := DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0))
	var catalog := DefenderCatalog.new([DefenderCatalog.Entry.new(&"square", knight_data, 1)])

	t.assert_eq(catalog.get_defender_data(&"square", 1), knight_data, "debe devolver el DefenderData mapeado a esa clave")

func test_devuelve_null_si_la_clave_no_esta_mapeada(t) -> void:
	var catalog := DefenderCatalog.new()

	t.assert_true(catalog.get_defender_data(&"unmapped", 1) == null, "una clave sin entrada debe devolver null")

func test_dos_entradas_del_mismo_tipo_con_distinto_rank_devuelven_defender_data_distintos(t) -> void:
	var rank_1_data := DefenderData.new(&"knight_rank_1", WeaponData.new(&"sword", 4, 1.0))
	var rank_2_data := DefenderData.new(&"knight_rank_2", WeaponData.new(&"sword", 6, 1.0))
	var catalog := DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", rank_1_data, 1),
		DefenderCatalog.Entry.new(&"square", rank_2_data, 2),
	])

	t.assert_eq(catalog.get_defender_data(&"square", 1), rank_1_data, "rank 1 debe devolver el DefenderData mapeado a rank 1")
	t.assert_eq(catalog.get_defender_data(&"square", 2), rank_2_data, "rank 2 debe devolver el DefenderData mapeado a rank 2")
