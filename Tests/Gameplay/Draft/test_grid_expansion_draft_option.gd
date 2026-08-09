extends RefCounted
## Tests básicos de GridExpansionDraftOption: agranda el grid al aplicarse.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const GridExpansionDraftOption = preload("res://Scripts/Gameplay/Draft/grid_expansion_draft_option.gd")

func test_apply_agranda_el_grid_en_las_dimensiones_indicadas(t) -> void:
	var grid := InventoryGrid.new(3, 3)
	var option := GridExpansionDraftOption.new(2, 1)

	option.apply(grid, null)

	t.assert_eq(grid.get_width(), 5, "apply debe agrandar el ancho en additional_width")
	t.assert_eq(grid.get_height(), 4, "apply debe agrandar el alto en additional_height")

func test_describe_incluye_las_dimensiones(t) -> void:
	var option := GridExpansionDraftOption.new(2, 1)

	t.assert_eq(option.describe(), "Grid +2x1", "describe debe incluir additional_width y additional_height")
