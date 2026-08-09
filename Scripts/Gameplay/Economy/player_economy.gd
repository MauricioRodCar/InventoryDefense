class_name PlayerEconomy
extends RefCounted
## Única autoridad sobre el oro del jugador. No conoce de dónde viene el oro
## (enemigos derrotados, recompensas de oleada, etc.) ni en qué se gasta
## (reroll de draft, etc.): solo protege el invariante de que el oro nunca es
## negativo, tanto al sumar como al restar, y emite gold_changed en cada
## cambio, igual que InventoryGrid es la única autoridad sobre qué celda está
## ocupada por qué pieza.

signal gold_changed(new_amount: int)

var _gold: int = 0

func get_gold() -> int:
	return _gold

func can_afford(amount: int) -> bool:
	return amount <= _gold

## amount debe ser positivo: quien llama (p. ej. BattleRunner vía
## EnemyRewardCatalog) es responsable de no invocar esto con una recompensa
## de 0 o negativa.
func add_gold(amount: int) -> void:
	assert(amount > 0, "add_gold requiere un amount positivo")
	_gold += amount
	gold_changed.emit(_gold)

## amount debe ser positivo, misma guarda que add_gold. No alcanzar el oro
## disponible es un caso esperado del flujo normal del juego (el jugador no
## puede pagar), no un error de programación: a diferencia de amount <= 0,
## no falla con assert, simplemente devuelve false sin mutar nada ni emitir
## señal.
func spend_gold(amount: int) -> bool:
	assert(amount > 0, "spend_gold requiere un amount positivo")
	if not can_afford(amount):
		return false
	_gold -= amount
	gold_changed.emit(_gold)
	return true
