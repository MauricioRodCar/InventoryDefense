extends RefCounted
## Tests básicos de Enemy: vida acotada y avance de progreso en el camino.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")

func test_un_enemigo_nuevo_esta_vivo_con_vida_maxima(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	t.assert_true(enemy.is_alive(), "un enemigo recién creado debe estar vivo")
	t.assert_eq(enemy.current_health, 10, "un enemigo recién creado debe empezar con la vida máxima")
	t.assert_eq(enemy.path_progress, 0.0, "un enemigo recién creado debe empezar en progreso 0")

func test_take_damage_reduce_la_vida_sin_bajar_de_cero(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	enemy._take_damage(4)
	t.assert_eq(enemy.current_health, 6, "el daño debe restarse de la vida actual")
	enemy._take_damage(100)
	t.assert_eq(enemy.current_health, 0, "la vida nunca debe quedar negativa")
	t.assert_true(not enemy.is_alive(), "un enemigo con 0 de vida no debe estar vivo")

func test_advance_incrementa_el_progreso_sin_bajar_de_cero(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	enemy._advance(2.5)
	t.assert_eq(enemy.path_progress, 2.5, "advance debe sumar el progreso indicado")
	enemy._advance(-100.0)
	t.assert_eq(enemy.path_progress, 0.0, "el progreso nunca debe quedar negativo")
