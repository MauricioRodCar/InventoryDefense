class_name DraftOption
extends RefCounted
## Contrato base para una opción de draft de fin de wave: qué efecto aplica
## si el jugador la elige y qué texto la describe. No se instancia
## directamente: cada tipo de recompensa compone una subclase concreta (ver
## PieceDraftOption, GridExpansionDraftOption). Agregar un tipo de recompensa
## nuevo es agregar una subclase, nunca modificar Draft ni DraftPool — mismo
## criterio ya documentado para WeaponBehavior/TargetingPolicy en Combat.
##
## apply() recibe siempre tanto InventoryGrid como InventoryPieceSource,
## aunque cada subclase concreta use solo una de las dos referencias e
## ignore la otra: así el contrato no tiene que cambiar si en el futuro
## aparece un tercer tipo de recompensa que necesite una referencia distinta.

const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")

## Aplica el efecto de esta opción. Las subclases concretas implementan el
## efecto real, usando solo la referencia que les corresponde.
func apply(grid: InventoryGrid, piece_source: InventoryPieceSource) -> void:
	pass

## Texto breve para la UI. Las subclases concretas implementan la descripción real.
func describe() -> String:
	return ""
