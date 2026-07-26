extends RefCounted
## Tests básicos de LowestProgressTargetingPolicy: selección de objetivo,
## sin mutar entidades.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const LowestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_progress_targeting_policy.gd")

func test_selecciona_al_enemigo_con_menor_path_progress(t) -> void:
	var behind := Enemy.new(&"behind", 10, 1.0)
	behind._advance(1.0)
	var ahead := Enemy.new(&"ahead", 10, 1.0)
	ahead._advance(5.0)
	var policy := LowestProgressTargetingPolicy.new()

	var target := policy.select_target([ahead, behind])

	t.assert_eq(target, behind, "debe seleccionar al enemigo con menor path_progress, sin importar el orden en la lista")

func test_ignora_enemigos_muertos(t) -> void:
	var dead := Enemy.new(&"dead", 10, 1.0)
	dead._take_damage(100)
	var alive := Enemy.new(&"alive", 10, 1.0)
	alive._advance(50.0)
	var policy := LowestProgressTargetingPolicy.new()

	var target := policy.select_target([dead, alive])

	t.assert_eq(target, alive, "un enemigo muerto nunca debe ser seleccionado aunque tenga menor path_progress")

func test_sin_enemigos_vivos_devuelve_null(t) -> void:
	var policy := LowestProgressTargetingPolicy.new()

	var target := policy.select_target([])

	t.assert_true(target == null, "sin enemigos vivos no debe haber ningún objetivo")
