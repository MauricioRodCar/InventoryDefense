extends RefCounted
## Tests básicos de CombatSimulation: orquesta MovementPhase/AttackPhase,
## aplica sus resultados y es la única emisora de señales de combate.

const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")
const Wave = preload("res://Scripts/Gameplay/Combat/wave.gd")
const CombatSimulation = preload("res://Scripts/Gameplay/Combat/combat_simulation.gd")
const StatusEffectData = preload("res://Scripts/Gameplay/Combat/status_effect_data.gd")

func test_advance_mueve_a_los_enemigos_vivos(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 10, 2.0)
	simulation.add_enemy(enemy)

	simulation.advance(0.5)

	t.assert_eq(enemy.path_progress, 1.0, "advance debe mover al enemigo según su velocidad y el delta")

func test_enemigo_que_llega_al_final_se_remueve_y_emite_la_senal(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(5.0))
	var enemy := Enemy.new(&"e1", 10, 10.0)
	simulation.add_enemy(enemy)
	var reached_events: Array = []
	simulation.enemy_reached_end.connect(func(e): reached_events.append(e))

	simulation.advance(1.0)

	t.assert_eq(reached_events, [enemy], "enemy_reached_end debe emitirse con el enemigo que llegó al final")
	t.assert_eq(simulation.get_enemies().size(), 0, "el enemigo que llega al final debe salir del roster")

func test_defensor_listo_ataca_al_objetivo_y_aplica_dano(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 10, 0.0)
	var weapon_instance := WeaponInstance.new(WeaponData.new(&"sword", 4, 1.0))
	var defender := Defender.new(&"d1", weapon_instance)
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)
	var attack_events: Array = []
	simulation.defender_attacked.connect(func(d, target, damage, is_critical): attack_events.append([d, target, damage, is_critical]))

	simulation.advance(0.1)

	t.assert_eq(enemy.current_health, 6, "el enemigo debe recibir el daño del arma del defensor")
	t.assert_eq(attack_events, [[defender, enemy, 4, false]], "defender_attacked debe emitirse con defensor, objetivo, daño y si fue crítico")
	t.assert_true(not weapon_instance.is_ready(), "atacar debe reiniciar el cooldown del arma")

func test_defender_attacked_propaga_is_critical(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 100, 0.0)
	var weapon_data := WeaponData.new(&"sword", 4, 1.0, null, 1.0, 2.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(weapon_data))
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)
	var attack_events: Array = []
	simulation.defender_attacked.connect(func(d, target, damage, is_critical): attack_events.append([d, target, damage, is_critical]))

	simulation.advance(0.1)

	t.assert_eq(attack_events, [[defender, enemy, roundi(4 * 2.0), true]], "con crit_chance en 1.0, defender_attacked debe emitirse con is_critical en true y el daño ya multiplicado")

func test_ataca_al_enemigo_con_mayor_path_progress(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var behind := Enemy.new(&"behind", 10, 0.0)
	var ahead := Enemy.new(&"ahead", 10, 0.0)
	ahead._advance(5.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 4, 1.0)))
	simulation.add_enemy(behind)
	simulation.add_enemy(ahead)
	simulation.add_defender(defender)

	simulation.advance(0.1)

	t.assert_eq(ahead.current_health, 6, "debe atacar al enemigo con mayor path_progress")
	t.assert_eq(behind.current_health, 10, "el enemigo con menor path_progress no debe recibir daño")

func test_enemigo_derrotado_se_remueve_y_emite_la_senal(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 3, 0.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)))
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)
	var defeated_events: Array = []
	simulation.enemy_defeated.connect(func(e): defeated_events.append(e))

	simulation.advance(0.1)

	t.assert_eq(defeated_events, [enemy], "enemy_defeated debe emitirse con el enemigo derrotado")
	t.assert_eq(simulation.get_enemies().size(), 0, "un enemigo derrotado debe salir del roster")

func test_el_cooldown_persiste_entre_llamadas_a_advance(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 10, 0.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 1, 1.0)))
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)

	simulation.advance(0.5)
	t.assert_eq(enemy.current_health, 9, "el primer advance debe disparar el ataque inicial")

	simulation.advance(0.5)
	t.assert_eq(enemy.current_health, 9, "el cooldown no debe haberse cumplido todavía tras un segundo advance de 0.5s con intervalo 1.0s")

func test_get_enemies_y_get_defenders_devuelven_copias(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 10, 0.0)
	simulation.add_enemy(enemy)

	var enemies := simulation.get_enemies()
	enemies.append(Enemy.new(&"e2", 10, 0.0))

	t.assert_eq(simulation.get_enemies().size(), 1, "mutar el array devuelto por get_enemies no debe afectar el roster interno")

func test_una_wave_puebla_el_roster_y_emite_enemy_spawned(t) -> void:
	var goblin_data := EnemyData.new(&"goblin", 7, 2.0)
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(0.0, goblin_data)]))
	var simulation := CombatSimulation.new(CombatPath.new(100.0), wave)
	var spawned_events: Array = []
	simulation.enemy_spawned.connect(func(e): spawned_events.append(e))

	simulation.advance(0.1)

	t.assert_eq(simulation.get_enemies().size(), 1, "un advance que alcanza el tiempo de una entrada debe añadir un enemigo al roster")
	var spawned_enemy: Enemy = simulation.get_enemies()[0]
	t.assert_eq(spawned_enemy.id, &"goblin", "el enemigo creado debe usar el id del EnemyData de la entrada")
	t.assert_eq(spawned_enemy.max_health, 7, "el enemigo creado debe usar la vida máxima del EnemyData de la entrada")
	t.assert_eq(spawned_enemy.speed, 2.0, "el enemigo creado debe usar la velocidad del EnemyData de la entrada")
	t.assert_eq(spawned_events, [spawned_enemy], "enemy_spawned debe emitirse con el enemigo recién creado")

func test_un_enemigo_recien_spawneado_no_se_mueve_en_el_mismo_advance(t) -> void:
	var goblin_data := EnemyData.new(&"goblin", 7, 5.0)
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(0.0, goblin_data)]))
	var simulation := CombatSimulation.new(CombatPath.new(100.0), wave)

	simulation.advance(1.0)

	t.assert_eq(simulation.get_enemies()[0].path_progress, 0.0, "un enemigo no debe avanzar en el mismo advance en el que fue spawneado")

func test_sin_wave_advance_no_agrega_enemigos_por_si_solo(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))

	simulation.advance(1.0)

	t.assert_eq(simulation.get_enemies().size(), 0, "sin una Wave configurada, advance no debe poblar el roster de enemigos")

func test_sin_wave_is_battle_over_siempre_es_falso(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	simulation.add_enemy(Enemy.new(&"e1", 10, 0.0))

	simulation.advance(1.0)

	t.assert_true(not simulation.is_battle_over(), "sin Wave no hay noción de fin de batalla, aunque el roster esté vacío o no")

func test_wave_completed_se_emite_una_sola_vez_al_agotar_el_calendario(t) -> void:
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(0.0, EnemyData.new(&"goblin", 7, 2.0))]))
	var simulation := CombatSimulation.new(CombatPath.new(100.0), wave)
	var completed_events: Array = []
	simulation.wave_completed.connect(func(): completed_events.append(true))

	simulation.advance(0.1)
	t.assert_eq(completed_events.size(), 1, "wave_completed debe emitirse en cuanto la wave agota su calendario")

	simulation.advance(0.1)
	t.assert_eq(completed_events.size(), 1, "wave_completed no debe volver a emitirse en advances posteriores")

func test_is_battle_over_solo_cuando_la_wave_termino_y_no_quedan_enemigos(t) -> void:
	var wave := Wave.new(WaveData.new([WaveData.SpawnEntry.new(0.0, EnemyData.new(&"goblin", 7, 0.0))]))
	var simulation := CombatSimulation.new(CombatPath.new(100.0), wave)

	simulation.advance(0.1)
	t.assert_true(not simulation.is_battle_over(), "la wave terminó pero el enemigo spawneado sigue vivo en el roster")

	var enemy: Enemy = simulation.get_enemies()[0]
	enemy._take_damage(7)
	simulation.advance(0.1)
	t.assert_true(simulation.is_battle_over(), "wave agotada y sin enemigos vivos: la batalla debe darse por terminada")

func test_un_defensor_con_status_effect_lo_aplica_al_enemigo_objetivo_tras_impactar(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 100, 0.0)
	var burn := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var weapon_data := WeaponData.new(&"sword", 4, 1.0, null, 0.0, 2.0, burn)
	var defender := Defender.new(&"d1", WeaponInstance.new(weapon_data))
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)

	simulation.advance(0.1)

	var active := enemy.get_active_status_effects()
	t.assert_eq(active.size(), 1, "un impacto de un arma con status_effect configurado debe aplicar el efecto al objetivo")
	t.assert_eq(active[0].status_effect_data.id, &"burn", "el efecto aplicado debe ser el configurado en el WeaponData del defensor")

func test_advances_sucesivos_tickean_el_efecto_y_emiten_status_effect_ticked_en_el_momento_esperado(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 100, 0.0)
	var burn := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var weapon_data := WeaponData.new(&"sword", 4, 100.0, null, 0.0, 2.0, burn)
	var defender := Defender.new(&"d1", WeaponInstance.new(weapon_data))
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)
	var tick_events: Array = []
	simulation.status_effect_ticked.connect(func(e, id, damage): tick_events.append([e, id, damage]))

	simulation.advance(0.1)
	t.assert_eq(tick_events.size(), 0, "el efecto recién aplicado no debe tickear todavía en el mismo advance en el que se aplicó")

	simulation.advance(0.9)
	t.assert_eq(tick_events, [[enemy, &"burn", 3]], "status_effect_ticked debe emitirse con el enemigo, el id del efecto y el daño del tick al cumplirse tick_interval")
	t.assert_eq(enemy.current_health, 100 - 4 - 3, "el enemigo debe perder tanto el daño directo del impacto como el daño acumulado del tick")

func test_el_dano_de_un_tick_de_efecto_puede_derrotar_a_un_enemigo(t) -> void:
	var simulation := CombatSimulation.new(CombatPath.new(100.0))
	var enemy := Enemy.new(&"e1", 5, 0.0)
	var burn := StatusEffectData.new(&"burn", 3, 1.0, 4.0)
	var weapon_data := WeaponData.new(&"sword", 2, 100.0, null, 0.0, 2.0, burn)
	var defender := Defender.new(&"d1", WeaponInstance.new(weapon_data))
	simulation.add_enemy(enemy)
	simulation.add_defender(defender)
	var defeated_events: Array = []
	simulation.enemy_defeated.connect(func(e): defeated_events.append(e))

	simulation.advance(0.1)
	simulation.advance(0.9)

	t.assert_eq(defeated_events, [enemy], "el daño de un tick de efecto de estado debe poder derrotar a un enemigo, igual que el daño directo")
	t.assert_eq(simulation.get_enemies().size(), 0, "un enemigo derrotado por un tick de efecto de estado debe salir del roster")
