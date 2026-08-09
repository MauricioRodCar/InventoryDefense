extends RefCounted
## Tests básicos de DefenderData: definición pura, sin estado de ejecución.

const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const LowestHealthTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_health_targeting_policy.gd")

func test_guarda_id_y_weapon_data(t) -> void:
	var weapon_data := WeaponData.new(&"sword", 4, 1.0)
	var defender_data := DefenderData.new(&"knight", weapon_data)

	t.assert_eq(defender_data.id, &"knight", "debe guardar el id recibido")
	t.assert_eq(defender_data.weapon_data, weapon_data, "debe guardar el WeaponData recibido")

func test_sin_targeting_policy_explicita_queda_null(t) -> void:
	var defender_data := DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0))

	t.assert_true(defender_data.targeting_policy == null, "sin targeting_policy explícita debe quedar null, para que Defender aplique su propio default")

func test_guarda_la_targeting_policy_indicada_explicitamente(t) -> void:
	var policy := LowestHealthTargetingPolicy.new()
	var defender_data := DefenderData.new(&"knight", WeaponData.new(&"sword", 4, 1.0), policy)

	t.assert_eq(defender_data.targeting_policy, policy, "debe guardar la TargetingPolicy que se le compuso explícitamente")
