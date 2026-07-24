extends RefCounted
## Tests básicos de ShapeData: representación de celdas y rotación.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")

func test_1x1_tiene_una_sola_celda(t) -> void:
	var shape := ShapeData.new(&"1x1", [Vector2i(0, 0)])
	t.assert_eq(shape.get_cells(), [Vector2i(0, 0)], "1x1 debe ocupar solo (0,0)")

func test_2x1_tiene_dos_celdas_horizontales(t) -> void:
	var shape := ShapeData.new(&"2x1", [Vector2i(0, 0), Vector2i(1, 0)])
	t.assert_eq(shape.get_cells(), [Vector2i(0, 0), Vector2i(1, 0)], "2x1 debe ocupar dos celdas en fila")

func test_2x2_tiene_cuatro_celdas(t) -> void:
	var shape := ShapeData.new(&"2x2", [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
	])
	t.assert_eq(shape.get_cells().size(), 4, "2x2 debe ocupar cuatro celdas")

func test_forma_l_rotada_90_grados(t) -> void:
	var shape := ShapeData.new(&"L", [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)
	])
	var expected: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 0)
	]
	t.assert_eq(shape.get_cells(1), expected, "L rotada 90° debe normalizarse a partir de (0,0)")

func test_rotacion_preserva_cantidad_de_celdas(t) -> void:
	var shape := ShapeData.new(&"T", [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)
	])
	for steps in range(4):
		t.assert_eq(shape.get_cells(steps).size(), 4, "T debe conservar 4 celdas en rotación %d" % steps)

func test_rotacion_completa_vuelve_al_origen(t) -> void:
	var shape := ShapeData.new(&"L", [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)
	])
	t.assert_eq(shape.get_cells(4), shape.get_cells(0), "4 rotaciones de 90° deben equivaler a 0")
