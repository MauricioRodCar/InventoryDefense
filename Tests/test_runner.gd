extends SceneTree
## Runner mínimo de tests unitarios, sin dependencias externas.
## Uso: godot --headless --script res://Tests/test_runner.gd

const TestShapeData = preload("res://Tests/Gameplay/Inventory/test_shape_data.gd")
const TestInventoryPiece = preload("res://Tests/Gameplay/Inventory/test_inventory_piece.gd")
const TestInventoryGrid = preload("res://Tests/Gameplay/Inventory/test_inventory_grid.gd")
const TestInventoryPieceSource = preload("res://Tests/Gameplay/Inventory/test_inventory_piece_source.gd")
const TestCombatPath = preload("res://Tests/Gameplay/Combat/test_combat_path.gd")
const TestWeaponData = preload("res://Tests/Gameplay/Combat/test_weapon_data.gd")
const TestWeaponInstance = preload("res://Tests/Gameplay/Combat/test_weapon_instance.gd")
const TestWeaponBehavior = preload("res://Tests/Gameplay/Combat/test_weapon_behavior.gd")
const TestSingleShotWeaponBehavior = preload("res://Tests/Gameplay/Combat/test_single_shot_weapon_behavior.gd")
const TestEnemy = preload("res://Tests/Gameplay/Combat/test_enemy.gd")
const TestEnemyData = preload("res://Tests/Gameplay/Combat/test_enemy_data.gd")
const TestDefender = preload("res://Tests/Gameplay/Combat/test_defender.gd")
const TestMovementPhase = preload("res://Tests/Gameplay/Combat/test_movement_phase.gd")
const TestAttackPhase = preload("res://Tests/Gameplay/Combat/test_attack_phase.gd")
const TestHighestProgressTargetingPolicy = preload("res://Tests/Gameplay/Combat/test_highest_progress_targeting_policy.gd")
const TestLowestHealthTargetingPolicy = preload("res://Tests/Gameplay/Combat/test_lowest_health_targeting_policy.gd")
const TestLowestProgressTargetingPolicy = preload("res://Tests/Gameplay/Combat/test_lowest_progress_targeting_policy.gd")
const TestWaveData = preload("res://Tests/Gameplay/Combat/test_wave_data.gd")
const TestWave = preload("res://Tests/Gameplay/Combat/test_wave.gd")
const TestCombatSimulation = preload("res://Tests/Gameplay/Combat/test_combat_simulation.gd")
const TestDefenderData = preload("res://Tests/Gameplay/Bridge/test_defender_data.gd")
const TestDefenderCatalog = preload("res://Tests/Gameplay/Bridge/test_defender_catalog.gd")
const TestDefenderTranslator = preload("res://Tests/Gameplay/Bridge/test_defender_translator.gd")
const TestCombatSimulationBuilder = preload("res://Tests/Gameplay/Bridge/test_combat_simulation_builder.gd")
const TestPlayerEconomy = preload("res://Tests/Gameplay/Economy/test_player_economy.gd")
const TestEnemyRewardCatalog = preload("res://Tests/Gameplay/Economy/test_enemy_reward_catalog.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	_run_suite(TestShapeData.new())
	_run_suite(TestInventoryPiece.new())
	_run_suite(TestInventoryGrid.new())
	_run_suite(TestInventoryPieceSource.new())
	_run_suite(TestCombatPath.new())
	_run_suite(TestWeaponData.new())
	_run_suite(TestWeaponInstance.new())
	_run_suite(TestWeaponBehavior.new())
	_run_suite(TestSingleShotWeaponBehavior.new())
	_run_suite(TestEnemy.new())
	_run_suite(TestEnemyData.new())
	_run_suite(TestDefender.new())
	_run_suite(TestMovementPhase.new())
	_run_suite(TestAttackPhase.new())
	_run_suite(TestHighestProgressTargetingPolicy.new())
	_run_suite(TestLowestHealthTargetingPolicy.new())
	_run_suite(TestLowestProgressTargetingPolicy.new())
	_run_suite(TestWaveData.new())
	_run_suite(TestWave.new())
	_run_suite(TestCombatSimulation.new())
	_run_suite(TestDefenderData.new())
	_run_suite(TestDefenderCatalog.new())
	_run_suite(TestDefenderTranslator.new())
	_run_suite(TestCombatSimulationBuilder.new())
	_run_suite(TestPlayerEconomy.new())
	_run_suite(TestEnemyRewardCatalog.new())

	print("")
	print("Resultado: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _run_suite(suite: Object) -> void:
	var suite_name: String = suite.get_script().resource_path.get_file()
	print("-- %s --" % suite_name)
	for method in suite.get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_"):
			suite.call(method_name, self)

func assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: %s" % message)

func assert_eq(actual, expected, message: String) -> void:
	assert_true(actual == expected, "%s (esperado=%s, actual=%s)" % [message, expected, actual])
