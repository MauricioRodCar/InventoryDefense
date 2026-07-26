extends RefCounted
## Tests básicos de SingleShotWeaponBehavior: un único impacto sobre el
## objetivo prioritario, por el daño base del arma, sin mutar entidades.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")

func test_produce_un_unico_impacto_sobre_el_objetivo_prioritario(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	var other := Enemy.new(&"other", 10, 1.0)
	var behavior := SingleShotWeaponBehavior.new()

	var hits := behavior.resolve(5, primary, [primary, other])

	t.assert_eq(hits.size(), 1, "un disparo único debe producir exactamente un impacto")
	t.assert_eq(hits[0].target, primary, "el impacto debe ser sobre el objetivo prioritario, nunca sobre otro enemigo de la lista")
	t.assert_eq(hits[0].damage, 5, "el daño del impacto debe ser el daño base indicado")

func test_no_muta_ninguna_entidad(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	var behavior := SingleShotWeaponBehavior.new()

	behavior.resolve(5, primary, [primary])

	t.assert_eq(primary.current_health, 10, "resolve no debe aplicar daño directamente: solo describe el impacto")
