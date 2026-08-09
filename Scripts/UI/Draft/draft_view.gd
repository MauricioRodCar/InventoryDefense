class_name DraftView
extends Control
## Vista mínima del draft de fin de wave: refleja el estado de un Draft
## dibujando sus 3 opciones y el botón de reroll. No conoce InventoryGrid ni
## InventoryPieceSource, y no llama ningún método que mute el dominio
## directamente: solo emite intención (option_selected/reroll_requested), es
## main.gd quien decide qué hacer con ella — mismo criterio que
## InventoryGridView/InventoryPieceSourceView con
## InventoryInteractionController.

const Draft = preload("res://Scripts/Gameplay/Draft/draft.gd")
const DraftOption = preload("res://Scripts/Gameplay/Draft/draft_option.gd")
const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")

signal option_selected(index: int)
signal reroll_requested()

@onready var _option_buttons: Array[Button] = [$VBoxContainer/Option0, $VBoxContainer/Option1, $VBoxContainer/Option2]
@onready var _reroll_button: Button = $RerollButton

var _draft: Draft
var _player_economy: PlayerEconomy

func _ready() -> void:
	for i in _option_buttons.size():
		_option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
	_reroll_button.pressed.connect(_on_reroll_pressed)
	hide()

## Punto de entrada único: entrega el draft y la economía a observar, pinta
## el estado inicial explícitamente (no depende de que se emita ninguna
## señal durante la construcción de draft, mismo motivo por el que
## InventoryGridView.set_inventory_grid() llama _render_all() en vez de
## esperar una señal) y muestra el panel.
func set_draft(draft: Draft, player_economy: PlayerEconomy) -> void:
	_disconnect_draft_and_economy()

	_draft = draft
	_player_economy = player_economy

	_draft.options_changed.connect(_on_options_changed)
	_draft.option_chosen.connect(_on_option_chosen)
	_player_economy.gold_changed.connect(_on_gold_changed)

	_render_options(_draft.get_current_options())
	_render_reroll_button()
	show()

func _exit_tree() -> void:
	_disconnect_draft_and_economy()

func _on_option_pressed(index: int) -> void:
	option_selected.emit(index)

func _on_reroll_pressed() -> void:
	reroll_requested.emit()

func _on_options_changed(options: Array[DraftOption]) -> void:
	_render_options(options)
	_render_reroll_button()

## Un draft resuelto no debe seguir reaccionando a cambios de oro ajenos a él.
func _on_option_chosen(_option: DraftOption) -> void:
	hide()
	_disconnect_draft_and_economy()

func _on_gold_changed(_new_amount: int) -> void:
	_render_reroll_button()

func _render_options(options: Array[DraftOption]) -> void:
	for i in _option_buttons.size():
		_option_buttons[i].text = options[i].describe()

func _render_reroll_button() -> void:
	var cost: int = _draft.get_reroll_cost()
	_reroll_button.text = "Reroll (%d oro)" % cost
	_reroll_button.disabled = not _player_economy.can_afford(cost)

func _disconnect_draft_and_economy() -> void:
	if _draft != null:
		if _draft.options_changed.is_connected(_on_options_changed):
			_draft.options_changed.disconnect(_on_options_changed)
		if _draft.option_chosen.is_connected(_on_option_chosen):
			_draft.option_chosen.disconnect(_on_option_chosen)
	if _player_economy != null:
		if _player_economy.gold_changed.is_connected(_on_gold_changed):
			_player_economy.gold_changed.disconnect(_on_gold_changed)
