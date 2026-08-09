class_name Draft
extends RefCounted
## Instancia en ejecución de un draft de fin de wave concreto: sortea
## OPTIONS_PER_DRAFT opciones desde un DraftPool y decide qué pasa cuando el
## jugador elige una o pide reroll. Única autoridad y único emisor de
## señales de este dominio (mismo rol que InventoryGrid/CombatSimulation en
## los suyos). No retiene ninguna referencia a InventoryGrid/
## InventoryPieceSource/PlayerEconomy más allá de los parámetros explícitos
## de cada llamada — mismo criterio que CombatSimulationBuilder.build() no
## arrastra estado entre llamadas.

const DraftPool = preload("res://Scripts/Gameplay/Draft/draft_pool.gd")
const DraftOption = preload("res://Scripts/Gameplay/Draft/draft_option.gd")
const InventoryGrid = preload("res://Scripts/Gameplay/Inventory/inventory_grid.gd")
const InventoryPieceSource = preload("res://Scripts/Gameplay/Inventory/inventory_piece_source.gd")
const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")

const OPTIONS_PER_DRAFT := 3

signal options_changed(options: Array[DraftOption])
signal option_chosen(option: DraftOption)

var _pool: DraftPool
var _rng: RandomNumberGenerator
var _reroll_cost: int
var _current_options: Array[DraftOption] = []

func _init(pool: DraftPool, rng: RandomNumberGenerator, reroll_cost: int) -> void:
	_pool = pool
	_rng = rng
	_reroll_cost = reroll_cost
	_roll()

func get_current_options() -> Array[DraftOption]:
	return _current_options.duplicate()

func get_reroll_cost() -> int:
	return _reroll_cost

## No valida que index esté en rango: quien llama (la UI) es responsable de
## no invocarlo con un índice inválido, mismo espíritu que
## PlayerEconomy.add_gold/spend_gold delegan la validación de
## precondiciones a quien llama.
func choose(index: int, grid: InventoryGrid, piece_source: InventoryPieceSource) -> void:
	var option: DraftOption = _current_options[index]
	option.apply(grid, piece_source)
	option_chosen.emit(option)

## Si player_economy.spend_gold() falla por falta de oro, no muta
## _current_options ni emite ninguna señal: quedarse sin oro suficiente es
## un resultado esperado del flujo normal del juego, no amerita ningún
## efecto sobre el draft en curso.
func reroll(player_economy: PlayerEconomy) -> bool:
	if not player_economy.spend_gold(_reroll_cost):
		return false
	_roll()
	return true

func _roll() -> void:
	_current_options = _pool.draw_options(OPTIONS_PER_DRAFT, _rng)
	options_changed.emit(_current_options)
