extends RefCounted
## Tests básicos de LowestHealthTargetingPolicy: selección de objetivo,
## sin mutar entidades.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const LowestHealthTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_health_targeting_policy.gd")

func test_selecciona_al_enemigo_con_menor_current_health(t) -> void:
	var weak := Enemy.new(&"weak", 10, 1.0)
	weak._take_damage(7)
	var strong := Enemy.new(&"strong", 10, 1.0)
	var policy := LowestHealthTargetingPolicy.new()

	var target := policy.select_target([strong, weak])

	t.assert_eq(target, weak, "debe seleccionar al enemigo con menor current_health, sin importar el orden en la lista")

func test_ignora_el_path_progress_al_elegir(t) -> void:
	var behind_but_weak := Enemy.new(&"behind_but_weak", 10, 1.0)
	behind_but_weak._take_damage(9)
	var ahead_but_strong := Enemy.new(&"ahead_but_strong", 10, 1.0)
	ahead_but_strong._advance(50.0)
	var policy := LowestHealthTargetingPolicy.new()

	var target := policy.select_target([ahead_but_strong, behind_but_weak])

	t.assert_eq(target, behind_but_weak, "debe priorizar menor vida sobre mayor avance en el camino")

func test_ignora_enemigos_muertos(t) -> void:
	var dead := Enemy.new(&"dead", 10, 1.0)
	dead._take_damage(100)
	var alive := Enemy.new(&"alive", 10, 1.0)
	var policy := LowestHealthTargetingPolicy.new()

	var target := policy.select_target([dead, alive])

	t.assert_eq(target, alive, "un enemigo muerto nunca debe ser seleccionado aunque tenga menor current_health")

func test_sin_enemigos_vivos_devuelve_null(t) -> void:
	var policy := LowestHealthTargetingPolicy.new()

	var target := policy.select_target([])

	t.assert_true(target == null, "sin enemigos vivos no debe haber ningún objetivo")
