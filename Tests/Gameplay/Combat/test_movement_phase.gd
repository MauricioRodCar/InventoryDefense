extends RefCounted
## Tests básicos de MovementPhase: calcula el avance de enemigos vivos sin mutarlos.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const MovementPhase = preload("res://Scripts/Gameplay/Combat/movement_phase.gd")

func test_un_enemigo_vivo_produce_un_resultado_segun_su_velocidad(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 2.0)
	var phase := MovementPhase.new()

	var results := phase.advance([enemy], 0.5)

	t.assert_eq(results.size(), 1, "un enemigo vivo debe producir exactamente un resultado")
	t.assert_eq(results[0].enemy, enemy, "el resultado debe referenciar al enemigo evaluado")
	t.assert_eq(results[0].delta_progress, 1.0, "delta_progress debe ser speed * delta")

func test_un_enemigo_muerto_no_produce_resultado(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 2.0)
	enemy._take_damage(100)
	var phase := MovementPhase.new()

	var results := phase.advance([enemy], 1.0)

	t.assert_eq(results.size(), 0, "un enemigo muerto no debe producir resultado de movimiento")

func test_advance_no_muta_al_enemigo(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 2.0)
	var phase := MovementPhase.new()

	phase.advance([enemy], 1.0)

	t.assert_eq(enemy.path_progress, 0.0, "MovementPhase no debe mutar path_progress directamente: solo devuelve el resultado")
