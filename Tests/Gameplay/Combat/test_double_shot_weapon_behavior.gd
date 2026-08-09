extends RefCounted
## Tests básicos de DoubleShotWeaponBehavior: dos impactos sobre el objetivo
## prioritario, sin mutar entidades.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const DoubleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/double_shot_weapon_behavior.gd")

func test_produce_dos_impactos_sobre_el_objetivo_prioritario(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	var other := Enemy.new(&"other", 10, 1.0)
	var behavior := DoubleShotWeaponBehavior.new()

	var hits := behavior.resolve(3, primary, [primary, other])

	t.assert_eq(hits.size(), 2, "un disparo doble debe producir exactamente dos impactos")
	t.assert_eq(hits[0].target, primary, "el primer impacto debe ser sobre el objetivo prioritario")
	t.assert_eq(hits[1].target, primary, "el segundo impacto también debe ser sobre el objetivo prioritario, nunca sobre otro enemigo")
	t.assert_eq(hits[0].damage, 3, "cada impacto debe llevar el daño base indicado")
	t.assert_eq(hits[1].damage, 3, "cada impacto debe llevar el daño base indicado")

func test_no_muta_ninguna_entidad(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	var behavior := DoubleShotWeaponBehavior.new()

	behavior.resolve(3, primary, [primary])

	t.assert_eq(primary.current_health, 10, "resolve no debe aplicar daño directamente: solo describe los impactos")
