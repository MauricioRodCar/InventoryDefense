extends RefCounted
## Tests básicos de AttackPhase: decide quién ataca a quién sin mutar entidades.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const AttackPhase = preload("res://Scripts/Gameplay/Combat/attack_phase.gd")
const HighestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/highest_progress_targeting_policy.gd")
const LowestHealthTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_health_targeting_policy.gd")
const LowestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_progress_targeting_policy.gd")

func test_un_defensor_listo_ataca_al_unico_enemigo_vivo(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)))
	var phase := AttackPhase.new()

	var results := phase.advance([defender], [enemy])

	t.assert_eq(results.size(), 1, "un defensor listo con un enemigo vivo debe producir un resultado")
	t.assert_eq(results[0].defender, defender, "el resultado debe referenciar al defensor que ataca")
	t.assert_eq(results[0].target, enemy, "el resultado debe referenciar al enemigo objetivo")
	t.assert_eq(results[0].damage, 5, "el daño del resultado debe ser el del WeaponData del defensor")

func test_un_defensor_sin_cooldown_listo_no_ataca(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var weapon_instance := WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0))
	weapon_instance._reset_cooldown()
	var defender := Defender.new(&"d1", weapon_instance)
	var phase := AttackPhase.new()

	var results := phase.advance([defender], [enemy])

	t.assert_eq(results.size(), 0, "un defensor con cooldown activo no debe producir un ataque")

func test_ataca_al_enemigo_con_mayor_path_progress(t) -> void:
	var behind := Enemy.new(&"behind", 10, 1.0)
	behind._advance(1.0)
	var ahead := Enemy.new(&"ahead", 10, 1.0)
	ahead._advance(5.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)))
	var phase := AttackPhase.new()

	var results := phase.advance([defender], [behind, ahead])

	t.assert_eq(results[0].target, ahead, "debe atacar al enemigo con mayor path_progress, sin importar el orden en la lista")

func test_ignora_enemigos_muertos_al_seleccionar_objetivo(t) -> void:
	var dead := Enemy.new(&"dead", 10, 1.0)
	dead._advance(100.0)
	dead._take_damage(100)
	var alive := Enemy.new(&"alive", 10, 1.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)))
	var phase := AttackPhase.new()

	var results := phase.advance([defender], [dead, alive])

	t.assert_eq(results[0].target, alive, "un enemigo muerto nunca debe ser seleccionado como objetivo aunque tenga mayor path_progress")

func test_sin_enemigos_vivos_no_produce_resultado(t) -> void:
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)))
	var phase := AttackPhase.new()

	var results := phase.advance([defender], [])

	t.assert_eq(results.size(), 0, "sin enemigos vivos no debe haber ningún resultado de ataque")

func test_advance_no_muta_ninguna_entidad(t) -> void:
	var enemy := Enemy.new(&"e1", 10, 1.0)
	var weapon_instance := WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0))
	var defender := Defender.new(&"d1", weapon_instance)
	var phase := AttackPhase.new()

	phase.advance([defender], [enemy])

	t.assert_eq(enemy.current_health, 10, "AttackPhase no debe aplicar daño directamente: solo devuelve el resultado")
	t.assert_true(weapon_instance.is_ready(), "AttackPhase no debe reiniciar el cooldown directamente: solo devuelve el resultado")

func test_cada_defensor_ataca_segun_su_propia_targeting_policy(t) -> void:
	# behind: menor path_progress, más vida. ahead: mayor path_progress, menos vida.
	var behind := Enemy.new(&"behind", 10, 1.0)
	behind._advance(1.0)
	var ahead := Enemy.new(&"ahead", 10, 1.0)
	ahead._advance(5.0)
	ahead._take_damage(8)

	var vanguard := Defender.new(&"vanguard", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)), HighestProgressTargetingPolicy.new())
	var finisher := Defender.new(&"finisher", WeaponInstance.new(WeaponData.new(&"dagger", 3, 1.0)), LowestHealthTargetingPolicy.new())
	var sentinel := Defender.new(&"sentinel", WeaponInstance.new(WeaponData.new(&"spear", 4, 1.0)), LowestProgressTargetingPolicy.new())
	var phase := AttackPhase.new()

	var results := phase.advance([vanguard, finisher, sentinel], [behind, ahead])

	t.assert_eq(results.size(), 3, "los tres defensores listos deben producir un resultado cada uno en el mismo advance")
	t.assert_eq(results[0].target, ahead, "vanguard (HighestProgressTargetingPolicy) debe atacar al enemigo más adelantado")
	t.assert_eq(results[1].target, ahead, "finisher (LowestHealthTargetingPolicy) debe atacar al enemigo con menos vida")
	t.assert_eq(results[2].target, behind, "sentinel (LowestProgressTargetingPolicy) debe atacar al enemigo menos adelantado")

func test_defensores_sin_targeting_policy_explicita_usan_highest_progress_por_defecto(t) -> void:
	var behind := Enemy.new(&"behind", 10, 1.0)
	behind._advance(1.0)
	var ahead := Enemy.new(&"ahead", 10, 1.0)
	ahead._advance(5.0)
	var defender := Defender.new(&"d1", WeaponInstance.new(WeaponData.new(&"sword", 5, 1.0)))
	var phase := AttackPhase.new()

	var results := phase.advance([defender], [behind, ahead])

	t.assert_eq(results[0].target, ahead, "un Defender sin targeting_policy explícita debe conservar la regla previa de AttackPhase: mayor path_progress")
