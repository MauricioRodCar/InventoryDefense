extends RefCounted
## Tests básicos de AttackPhase: decide quién ataca a quién sin mutar entidades.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const WeaponInstance = preload("res://Scripts/Gameplay/Combat/weapon_instance.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const Defender = preload("res://Scripts/Gameplay/Combat/defender.gd")
const AttackPhase = preload("res://Scripts/Gameplay/Combat/attack_phase.gd")

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
