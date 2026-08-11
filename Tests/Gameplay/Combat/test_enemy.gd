extends RefCounted
## Tests básicos de Enemy: vida acotada, avance de progreso en el camino y
## ciclo de vida de efectos de estado (aplicar, refrescar, tickear).

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")

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

func test_apply_status_effect_sin_resistencia_guarda_el_damage_per_tick_sin_modificar(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0, 0.0)
	var data := StatusEffectData.new(&"burn", 4, 1.0, 4.0)

	enemy._apply_status_effect(data)

	var active := enemy.get_active_status_effects()
	t.assert_eq(active.size(), 1, "aplicar un efecto de estado debe agregar una instancia activa")
	t.assert_eq(active[0].damage_per_tick, 4, "sin resistencia, damage_per_tick no debe modificarse")

func test_apply_status_effect_con_resistencia_0_5_guarda_la_mitad_redondeado(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0, 0.5)
	var data := StatusEffectData.new(&"burn", 5, 1.0, 4.0)

	enemy._apply_status_effect(data)

	var active := enemy.get_active_status_effects()
	t.assert_eq(active[0].damage_per_tick, roundi(5 * 0.5), "con resistencia 0.5, damage_per_tick debe guardarse a la mitad, redondeado")

func test_apply_status_effect_con_resistencia_1_0_no_agrega_nada(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0, 1.0)
	var data := StatusEffectData.new(&"burn", 4, 1.0, 4.0)

	enemy._apply_status_effect(data)

	t.assert_eq(enemy.get_active_status_effects().size(), 0, "con resistencia 1.0 (inmunidad total), no debe trackearse ningún efecto")

func test_reaplicar_el_mismo_id_reemplaza_la_instancia_anterior(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var data := StatusEffectData.new(&"burn", 4, 1.0, 4.0)

	enemy._apply_status_effect(data)
	enemy._tick_status_effects(2.0)
	enemy._apply_status_effect(data)

	var active := enemy.get_active_status_effects()
	t.assert_eq(active.size(), 1, "reaplicar el mismo id no debe acumular una segunda instancia")
	t.assert_eq(active[0].remaining_duration, 4.0, "reaplicar el mismo id debe refrescar la duración")

func test_dos_efectos_con_id_distinto_coexisten(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var burn := StatusEffectData.new(&"burn", 4, 1.0, 4.0)
	var poison := StatusEffectData.new(&"poison", 2, 1.0, 6.0)

	enemy._apply_status_effect(burn)
	enemy._apply_status_effect(poison)

	t.assert_eq(enemy.get_active_status_effects().size(), 2, "dos efectos de estado con id distinto deben coexistir como dos instancias activas")

func test_tick_status_effects_devuelve_un_tick_por_efecto_que_toca_y_remueve_los_expirados(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var burn := StatusEffectData.new(&"burn", 4, 1.0, 1.0)
	var poison := StatusEffectData.new(&"poison", 2, 2.0, 10.0)
	enemy._apply_status_effect(burn)
	enemy._apply_status_effect(poison)

	var ticks := enemy._tick_status_effects(1.0)

	t.assert_eq(ticks.size(), 1, "solo debe tickear el efecto cuyo tick_interval se cumplió en este delta")
	t.assert_eq(ticks[0].status_effect_id, &"burn", "el tick devuelto debe corresponder al efecto que tocaba tickear")
	t.assert_eq(ticks[0].damage, 4, "el tick devuelto debe llevar el damage_per_tick del efecto")
	t.assert_eq(enemy.get_active_status_effects().size(), 1, "el efecto expirado (burn, duration 1.0) debe removerse tras tickearlo")
