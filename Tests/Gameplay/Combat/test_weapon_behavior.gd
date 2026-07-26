extends RefCounted
## Tests básicos del contrato base WeaponBehavior: no produce impactos por
## sí mismo, y su Hit interno solo guarda objetivo y daño.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const WeaponBehavior = preload("res://Scripts/Gameplay/Combat/weapon_behavior.gd")

func test_resolve_sin_implementar_no_produce_impactos(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var behavior := WeaponBehavior.new()

	var hits := behavior.resolve(5, enemy, [enemy])

	t.assert_eq(hits.size(), 0, "el contrato base no debe producir ningún impacto por sí mismo")

func test_hit_guarda_el_objetivo_y_el_dano_indicados(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var hit := WeaponBehavior.Hit.new(enemy, 7)

	t.assert_eq(hit.target, enemy, "Hit debe guardar el objetivo indicado")
	t.assert_eq(hit.damage, 7, "Hit debe guardar el daño indicado")
