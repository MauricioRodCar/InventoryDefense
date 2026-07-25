extends SceneTree
## Runner mínimo de tests unitarios, sin dependencias externas.
## Uso: godot --headless --script res://Tests/test_runner.gd

const TestShapeData = preload("res://Tests/Gameplay/Inventory/test_shape_data.gd")
const TestInventoryPiece = preload("res://Tests/Gameplay/Inventory/test_inventory_piece.gd")
const TestInventoryGrid = preload("res://Tests/Gameplay/Inventory/test_inventory_grid.gd")
const TestInventoryPieceSource = preload("res://Tests/Gameplay/Inventory/test_inventory_piece_source.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	_run_suite(TestShapeData.new())
	_run_suite(TestInventoryPiece.new())
	_run_suite(TestInventoryGrid.new())
	_run_suite(TestInventoryPieceSource.new())

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
