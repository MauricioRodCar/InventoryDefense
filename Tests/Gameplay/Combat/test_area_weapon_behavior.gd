extends RefCounted
## Tests básicos de AreaWeaponBehavior: impacto sobre todo enemigo vivo
## dentro de radius de path_progress respecto al objetivo prioritario, sin
## falloff por distancia, sin mutar entidades.

const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const AreaWeaponBehavior = preload("res://Scripts/Gameplay/Combat/area_weapon_behavior.gd")

func test_incluye_siempre_al_objetivo_prioritario(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	var behavior := AreaWeaponBehavior.new(0.0)

	var hits := behavior.resolve(3, primary, [primary])

	t.assert_eq(hits.size(), 1, "el objetivo prioritario siempre debe recibir un impacto, incluso con radius 0")
	t.assert_eq(hits[0].target, primary, "el impacto debe ser sobre el objetivo prioritario")

func test_incluye_a_otro_enemigo_dentro_del_radio(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	primary.path_progress = 100.0
	var nearby := Enemy.new(&"nearby", 10, 1.0)
	nearby.path_progress = 130.0
	var behavior := AreaWeaponBehavior.new(60.0)

	var hits := behavior.resolve(3, primary, [primary, nearby])

	t.assert_eq(hits.size(), 2, "un enemigo dentro del radio también debe recibir un impacto")
	var targets := [hits[0].target, hits[1].target]
	t.assert_true(targets.has(nearby), "el enemigo cercano debe estar entre los impactos")

func test_no_incluye_a_un_enemigo_fuera_del_radio(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	primary.path_progress = 100.0
	var far := Enemy.new(&"far", 10, 1.0)
	far.path_progress = 200.0
	var behavior := AreaWeaponBehavior.new(60.0)

	var hits := behavior.resolve(3, primary, [primary, far])

	t.assert_eq(hits.size(), 1, "un enemigo fuera del radio no debe recibir ningún impacto")
	t.assert_eq(hits[0].target, primary, "solo el objetivo prioritario debe seguir recibiendo impacto")

func test_enemigo_en_el_borde_exacto_del_radio_se_incluye(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	primary.path_progress = 100.0
	var edge := Enemy.new(&"edge", 10, 1.0)
	edge.path_progress = 160.0
	var behavior := AreaWeaponBehavior.new(60.0)

	var hits := behavior.resolve(3, primary, [primary, edge])

	t.assert_eq(hits.size(), 2, "un enemigo exactamente a distancia == radius debe incluirse (operador <=, no <)")

func test_ignora_enemigos_muertos_aunque_esten_dentro_del_radio(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	primary.path_progress = 100.0
	var dead := Enemy.new(&"dead", 10, 1.0)
	dead.path_progress = 110.0
	dead._take_damage(10)
	var behavior := AreaWeaponBehavior.new(60.0)

	var hits := behavior.resolve(3, primary, [primary, dead])

	t.assert_eq(hits.size(), 1, "un enemigo muerto no debe recibir ningún impacto aunque esté dentro del radio")
	t.assert_eq(hits[0].target, primary, "solo el objetivo prioritario, vivo, debe recibir impacto")

func test_cada_impacto_lleva_el_dano_base_completo_sin_falloff(t) -> void:
	var primary := Enemy.new(&"primary", 10, 1.0)
	primary.path_progress = 100.0
	var nearby := Enemy.new(&"nearby", 10, 1.0)
	nearby.path_progress = 110.0
	var farther := Enemy.new(&"farther", 10, 1.0)
	farther.path_progress = 150.0
	var behavior := AreaWeaponBehavior.new(60.0)

	var hits := behavior.resolve(3, primary, [primary, nearby, farther])

	t.assert_eq(hits.size(), 3, "los tres enemigos deben recibir impacto")
	for hit in hits:
		t.assert_eq(hit.damage, 3, "cada impacto debe llevar el daño base completo, sin importar la distancia dentro del radio")
