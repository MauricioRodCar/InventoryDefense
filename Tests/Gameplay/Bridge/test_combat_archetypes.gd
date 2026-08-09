extends RefCounted
## Tests de integración de los tres arquetipos de defensor de sandbox
## (Vanguardia, Rematador, Artillero). Prueban que la arquitectura actual
## permite diferenciarlos únicamente por composición de WeaponData,
## WeaponBehavior y TargetingPolicy ya existentes, sin ninguna subclase
## nueva de Defender/WeaponData/DefenderData, y que DefenderCatalog +
## DefenderTranslator + CombatSimulation siguen funcionando sin
## modificaciones para producirlos y ejecutarlos en combate.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")
const WeaponData = preload("res://Scripts/Gameplay/Combat/weapon_data.gd")
const SingleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/single_shot_weapon_behavior.gd")
const DoubleShotWeaponBehavior = preload("res://Scripts/Gameplay/Combat/double_shot_weapon_behavior.gd")
const HighestProgressTargetingPolicy = preload("res://Scripts/Gameplay/Combat/highest_progress_targeting_policy.gd")
const LowestHealthTargetingPolicy = preload("res://Scripts/Gameplay/Combat/lowest_health_targeting_policy.gd")
const CombatPath = preload("res://Scripts/Gameplay/Combat/combat_path.gd")
const Enemy = preload("res://Scripts/Gameplay/Combat/enemy.gd")
const CombatSimulation = preload("res://Scripts/Gameplay/Combat/combat_simulation.gd")
const DefenderData = preload("res://Scripts/Gameplay/Bridge/defender_data.gd")
const DefenderCatalog = preload("res://Scripts/Gameplay/Bridge/defender_catalog.gd")
const DefenderTranslator = preload("res://Scripts/Gameplay/Bridge/defender_translator.gd")

## Misma configuración que main.gd compone para el sandbox: tres
## DefenderData distintos, cada uno combinando WeaponData/WeaponBehavior/
## TargetingPolicy ya existentes, mapeados a los tres tipos de pieza que ya
## ofrece InventoryPieceSourceSandbox (square, bar, corner).
func _build_archetype_catalog() -> DefenderCatalog:
	var vanguard_data := DefenderData.new(&"vanguard_defender", WeaponData.new(&"vanguard_weapon", 8, 2.0, SingleShotWeaponBehavior.new()), HighestProgressTargetingPolicy.new())
	var finisher_data := DefenderData.new(&"finisher_defender", WeaponData.new(&"finisher_weapon", 4, 0.5, SingleShotWeaponBehavior.new()), LowestHealthTargetingPolicy.new())
	var artillery_data := DefenderData.new(&"artillery_defender", WeaponData.new(&"artillery_weapon", 2, 1.0, DoubleShotWeaponBehavior.new()), HighestProgressTargetingPolicy.new())
	return DefenderCatalog.new([
		DefenderCatalog.Entry.new(&"square", vanguard_data),
		DefenderCatalog.Entry.new(&"bar", finisher_data),
		DefenderCatalog.Entry.new(&"corner", artillery_data),
	])

func test_el_catalogo_contiene_los_tres_arquetipos(t) -> void:
	var catalog := _build_archetype_catalog()

	t.assert_true(catalog.get_defender_data(&"square") != null, "square debe estar mapeado a Vanguardia")
	t.assert_true(catalog.get_defender_data(&"bar") != null, "bar debe estar mapeado a Rematador")
	t.assert_true(catalog.get_defender_data(&"corner") != null, "corner debe estar mapeado a Artillero")

func test_vanguardia_compone_highest_progress_y_single_shot_con_dano_alto_y_cadencia_lenta(t) -> void:
	var vanguard_data := _build_archetype_catalog().get_defender_data(&"square")

	t.assert_true(vanguard_data.targeting_policy is HighestProgressTargetingPolicy, "Vanguardia debe apuntar al enemigo más adelantado")
	t.assert_true(vanguard_data.weapon_data.weapon_behavior is SingleShotWeaponBehavior, "Vanguardia debe atacar con un único impacto")
	t.assert_eq(vanguard_data.weapon_data.damage, 8, "Vanguardia debe tener daño alto")
	t.assert_eq(vanguard_data.weapon_data.attack_interval, 2.0, "Vanguardia debe tener cadencia lenta")

func test_rematador_compone_lowest_health_y_single_shot_con_dano_medio_y_cadencia_rapida(t) -> void:
	var finisher_data := _build_archetype_catalog().get_defender_data(&"bar")

	t.assert_true(finisher_data.targeting_policy is LowestHealthTargetingPolicy, "Rematador debe apuntar al enemigo con menos vida")
	t.assert_true(finisher_data.weapon_data.weapon_behavior is SingleShotWeaponBehavior, "Rematador debe atacar con un único impacto")
	t.assert_eq(finisher_data.weapon_data.damage, 4, "Rematador debe tener daño medio")
	t.assert_eq(finisher_data.weapon_data.attack_interval, 0.5, "Rematador debe tener cadencia rápida")

func test_artillero_compone_highest_progress_y_double_shot_con_dano_menor(t) -> void:
	var artillery_data := _build_archetype_catalog().get_defender_data(&"corner")

	t.assert_true(artillery_data.targeting_policy is HighestProgressTargetingPolicy, "Artillero debe apuntar al enemigo más adelantado")
	t.assert_true(artillery_data.weapon_data.weapon_behavior is DoubleShotWeaponBehavior, "Artillero debe atacar con dos impactos")
	t.assert_eq(artillery_data.weapon_data.damage, 2, "Artillero debe tener daño menor que Vanguardia y Rematador")

func test_defender_translator_conserva_la_composicion_de_cada_arquetipo(t) -> void:
	var catalog := _build_archetype_catalog()
	var translator := DefenderTranslator.new()
	var vanguard_piece := InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)]))
	var finisher_piece := InventoryPiece.new(&"bar", ShapeData.new(&"3x1", [Vector2i(0, 0)]))
	var artillery_piece := InventoryPiece.new(&"corner", ShapeData.new(&"corner", [Vector2i(0, 0)]))

	var vanguard := translator.translate(vanguard_piece, catalog)
	var finisher := translator.translate(finisher_piece, catalog)
	var artillery := translator.translate(artillery_piece, catalog)

	t.assert_true(vanguard.targeting_policy is HighestProgressTargetingPolicy, "el Defender traducido de Vanguardia debe conservar su TargetingPolicy")
	t.assert_true(vanguard.weapon_instance.weapon_data.weapon_behavior is SingleShotWeaponBehavior, "el Defender traducido de Vanguardia debe conservar su WeaponBehavior")

	t.assert_true(finisher.targeting_policy is LowestHealthTargetingPolicy, "el Defender traducido de Rematador debe conservar su TargetingPolicy")
	t.assert_true(finisher.weapon_instance.weapon_data.weapon_behavior is SingleShotWeaponBehavior, "el Defender traducido de Rematador debe conservar su WeaponBehavior")

	t.assert_true(artillery.targeting_policy is HighestProgressTargetingPolicy, "el Defender traducido de Artillero debe conservar su TargetingPolicy")
	t.assert_true(artillery.weapon_instance.weapon_data.weapon_behavior is DoubleShotWeaponBehavior, "el Defender traducido de Artillero debe conservar su WeaponBehavior")

## Prueba de humo: los tres arquetipos, traducidos vía DefenderTranslator,
## deben poder combatir dentro de una CombatSimulation real sin que esta
## necesite ningún cambio. Confirma en particular que Artillero (DoubleShot)
## produce dos impactos por ataque también atravesando el motor completo.
func test_los_tres_arquetipos_combaten_correctamente_en_combat_simulation_sin_modificarla(t) -> void:
	var catalog := _build_archetype_catalog()
	var translator := DefenderTranslator.new()
	var vanguard := translator.translate(InventoryPiece.new(&"square", ShapeData.new(&"2x2", [Vector2i(0, 0)])), catalog)
	var finisher := translator.translate(InventoryPiece.new(&"bar", ShapeData.new(&"3x1", [Vector2i(0, 0)])), catalog)
	var artillery := translator.translate(InventoryPiece.new(&"corner", ShapeData.new(&"corner", [Vector2i(0, 0)])), catalog)

	var simulation := CombatSimulation.new(CombatPath.new(1000.0))
	simulation.add_defender(vanguard)
	simulation.add_defender(finisher)
	simulation.add_defender(artillery)
	var enemy := Enemy.new(&"goblin", 50, 0.0)
	simulation.add_enemy(enemy)

	# Array en vez de int local: los lambdas de GDScript capturan variables
	# locales por valor, no por referencia, así que un int se congelaría en 0.
	var attack_count := [0]
	simulation.defender_attacked.connect(func(_defender, _target, _damage): attack_count[0] += 1)

	simulation.advance(2.0)

	t.assert_eq(attack_count[0], 4, "en un mismo advance, los tres defensores listos deben atacar: Vanguardia (1) + Rematador (1) + Artillero (2 impactos) = 4 resultados, sin cambiar CombatSimulation/AttackPhase")
