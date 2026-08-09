class_name GoldCounterView
extends Label
## Vista mínima y reactiva del oro del jugador, mismo patrón que el resto de
## la capa UI: pinta el estado inicial explícitamente en set_player_economy()
## en vez de depender de que se emita una señal durante la construcción de
## PlayerEconomy, y luego se mantiene sincronizada escuchando gold_changed.
## No conoce de dónde viene ni en qué se gasta el oro.

const PlayerEconomy = preload("res://Scripts/Gameplay/Economy/player_economy.gd")

var _player_economy: PlayerEconomy

func set_player_economy(economy: PlayerEconomy) -> void:
	_disconnect_player_economy()

	_player_economy = economy
	if _player_economy == null:
		return

	_player_economy.gold_changed.connect(_on_gold_changed)
	_render_gold(_player_economy.get_gold())

func _exit_tree() -> void:
	_disconnect_player_economy()

func _on_gold_changed(new_amount: int) -> void:
	_render_gold(new_amount)

func _render_gold(amount: int) -> void:
	text = "Oro: %d" % amount

func _disconnect_player_economy() -> void:
	if _player_economy == null:
		return
	if _player_economy.gold_changed.is_connected(_on_gold_changed):
		_player_economy.gold_changed.disconnect(_on_gold_changed)
