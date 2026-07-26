class_name PlayerEconomy
extends RefCounted
## Única autoridad sobre el oro del jugador. No conoce de dónde viene el oro
## (enemigos derrotados, recompensas de oleada, etc.) ni quién lo gastará:
## solo protege el invariante de que el oro nunca es negativo y emite
## gold_changed en cada cambio, igual que InventoryGrid es la única
## autoridad sobre qué celda está ocupada por qué pieza.

signal gold_changed(new_amount: int)

var _gold: int = 0

func get_gold() -> int:
	return _gold

## amount debe ser positivo: quien llama (p. ej. BattleRunner vía
## EnemyRewardCatalog) es responsable de no invocar esto con una recompensa
## de 0 o negativa.
func add_gold(amount: int) -> void:
	assert(amount > 0, "add_gold requiere un amount positivo")
	_gold += amount
	gold_changed.emit(_gold)
