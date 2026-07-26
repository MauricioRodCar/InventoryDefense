extends RefCounted
## Tests básicos de EnemyRewardCatalog: mapeo de id de EnemyData a oro.

const EnemyRewardCatalog = preload("res://Scripts/Gameplay/Economy/enemy_reward_catalog.gd")

func test_devuelve_el_oro_asociado_a_una_clave(t) -> void:
	var catalog := EnemyRewardCatalog.new([EnemyRewardCatalog.Entry.new(&"goblin", 5)])

	t.assert_eq(catalog.get_gold_reward(&"goblin"), 5, "debe devolver el oro mapeado a esa clave")

func test_devuelve_cero_si_la_clave_no_esta_mapeada(t) -> void:
	var catalog := EnemyRewardCatalog.new()

	t.assert_eq(catalog.get_gold_reward(&"unmapped"), 0, "una clave sin entrada debe devolver 0")
