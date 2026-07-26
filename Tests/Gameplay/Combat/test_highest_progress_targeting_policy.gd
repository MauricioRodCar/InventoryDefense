extends RefCounted
## Tests básicos de HighestProgressTargetingPolicy: selección de objetivo,
## sin mutar entidades.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const HighestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/highest_progress_targeting_policy.gd")

func test_selecciona_al_enemigo_con_mayor_path_progress(t) -> void:
	var behind := Enemy.new(&"behind", 10, 1.0)
	behind._advance(1.0)
	var ahead := Enemy.new(&"ahead", 10, 1.0)
	ahead._advance(5.0)
	var policy := HighestProgressTargetingPolicy.new()

	var target := policy.select_target([behind, ahead])

	t.assert_eq(target, ahead, "debe seleccionar al enemigo con mayor path_progress, sin importar el orden en la lista")

func test_ignora_enemigos_muertos(t) -> void:
	var dead := Enemy.new(&"dead", 10, 1.0)
	dead._advance(100.0)
	dead._take_damage(100)
	var alive := Enemy.new(&"alive", 10, 1.0)
	var policy := HighestProgressTargetingPolicy.new()

	var target := policy.select_target([dead, alive])

	t.assert_eq(target, alive, "un enemigo muerto nunca debe ser seleccionado aunque tenga mayor path_progress")

func test_sin_enemigos_vivos_devuelve_null(t) -> void:
	var policy := HighestProgressTargetingPolicy.new()

	var target := policy.select_target([])

	t.assert_true(target == null, "sin enemigos vivos no debe haber ningún objetivo")
