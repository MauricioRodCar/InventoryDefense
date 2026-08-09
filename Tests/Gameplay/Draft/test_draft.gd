extends RefCounted
## Tests básicos de Draft: sorteo inicial, elegir una opción y reroll
## pagando oro.

const ShapeData = preload("res://Scripts/Gameplay/Inventory/shape_data.gd")
const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")
const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")
const PieceDraftOption = preload("res://Scripts/Gameplay/Draft/piece_draft_option.gd")
const DraftPool = preload("res://Scripts/Gameplay/Draft/draft_pool.gd")
const Draft = preload("res://Scripts/Gameplay/Draft/draft.gd")

const REROLL_COST := 5

## Un pool de una sola PieceDraftOption conocida, para que el resultado del
## sorteo sea siempre esa misma opción y los tests no dependan de qué tocó.
func _make_single_option_pool() -> DraftPool:
	var option := PieceDraftOption.new(&"square", ShapeData.new(&"1x1", [Vector2i(0, 0)]))
	return DraftPool.new([DraftPool.Entry.new(option, 1.0)])

func test_al_construirse_sortea_options_per_draft_opciones(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var draft := Draft.new(_make_single_option_pool(), rng, REROLL_COST)

	t.assert_eq(draft.get_current_options().size(), Draft.OPTIONS_PER_DRAFT, "el draft debe arrancar con OPTIONS_PER_DRAFT opciones")

func test_choose_aplica_la_opcion_y_emite_option_chosen(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var draft := Draft.new(_make_single_option_pool(), rng, REROLL_COST)
	var grid := InventoryGrid.new(4, 4)
	var piece_source := InventoryPieceSource.new()
	var chosen_options: Array = []
	draft.option_chosen.connect(func(option): chosen_options.append(option))

	draft.choose(0, grid, piece_source)

	t.assert_eq(piece_source.get_available_pieces().size(), 1, "choose debe aplicar la opción elegida sobre piece_source")
	t.assert_eq(chosen_options.size(), 1, "option_chosen debe emitirse exactamente una vez")
	t.assert_eq(chosen_options[0], draft.get_current_options()[0], "option_chosen debe emitir la opción elegida")

func test_reroll_con_oro_suficiente_descuenta_y_re_sortea(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var draft := Draft.new(_make_single_option_pool(), rng, REROLL_COST)
	var economy := PlayerEconomy.new()
	economy.add_gold(10)
	var changed_events: Array = []
	draft.options_changed.connect(func(options): changed_events.append(options))

	var result := draft.reroll(economy)

	t.assert_true(result, "reroll debe devolver true cuando el oro alcanza")
	t.assert_eq(economy.get_gold(), 5, "reroll debe descontar exactamente reroll_cost")
	t.assert_eq(changed_events.size(), 1, "options_changed debe emitirse en un reroll exitoso")

func test_reroll_con_oro_insuficiente_no_muta_nada(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var draft := Draft.new(_make_single_option_pool(), rng, REROLL_COST)
	var economy := PlayerEconomy.new()

	var result := draft.reroll(economy)

	t.assert_true(not result, "reroll debe devolver false cuando el oro no alcanza")
	t.assert_eq(economy.get_gold(), 0, "reroll no debe mutar el oro cuando falla")
