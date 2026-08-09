class_name PieceDraftOption
extends DraftOption
## DraftOption concreta: ofrece una InventoryPiece nueva a través de
## InventoryPieceSource al elegirse. No la coloca directamente en el grid —
## el jugador la arrastra él mismo, igual que cualquier otra pieza ofrecida
## — así que el único limitante real de esta recompensa es si le entra en
## el grid actual. InventoryGrid/InventoryPieceSource se heredan de
## DraftOption: no se redeclaran aquí.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryPiece = preload("res://Scripts/Gameplay/Inventory/inventory_piece.gd")

var type_id: StringName
var shape: ShapeData

func _init(p_type_id: StringName, p_shape: ShapeData) -> void:
	type_id = p_type_id
	shape = p_shape

func apply(_grid: InventoryGrid, piece_source: InventoryPieceSource) -> void:
	piece_source.offer_piece(InventoryPiece.new(type_id, shape))

func describe() -> String:
	return "Pieza: %s" % type_id
