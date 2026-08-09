class_name GridExpansionDraftOption
extends DraftOption
## DraftOption concreta: agranda el InventoryGrid en runtime al elegirse,
## delegando en su API ya existente (expand()). InventoryGrid/
## InventoryPieceSource se heredan de DraftOption: no se redeclaran aquí.

var additional_width: int
var additional_height: int

func _init(p_additional_width: int, p_additional_height: int) -> void:
	additional_width = p_additional_width
	additional_height = p_additional_height

func apply(grid: InventoryGrid, _piece_source: InventoryPieceSource) -> void:
	grid.expand(additional_width, additional_height)

func describe() -> String:
	return "Grid +%dx%d" % [additional_width, additional_height]
