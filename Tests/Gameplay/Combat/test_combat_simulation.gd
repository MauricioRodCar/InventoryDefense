extends RefCounted
## Tests básicos de CombatSimulation: orquesta MovementPhase/AttackPhase,
## aplica sus resultados y es la única emisora de señales de combate.

const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const CombatSimulation = preload("res://Scripts/Gameplay/Combat/combat_simulation.gd")

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
	simulation.defender_attacked.connect(func(d, target, damage): attack_events.append([d, target, damage]))

	simulation.advance(0.1)

	t.assert_eq(enemy.current_health, 6, "el enemigo debe recibir el daño del arma del defensor")
	t.assert_eq(attack_events, [[defender, enemy, 4]], "defender_attacked debe emitirse con defensor, objetivo y daño")
	t.assert_true(not weapon_instance.is_ready(), "atacar debe reiniciar el cooldown del arma")

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
