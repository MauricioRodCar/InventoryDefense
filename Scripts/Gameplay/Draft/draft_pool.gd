class_name DraftPool
extends RefCounted
## Definición pura de qué DraftOption puede ofrecer un draft y con qué peso
## relativo cada una: compartible, sin estado de ejecución, no genera nada
## por sí sola (eso vive en Draft). Mismo rol que WaveData/DefenderCatalog
## respecto a Wave/CombatSimulation.

const DraftOption = preload("res://Scripts/Gameplay/Draft/draft_option.gd")

## Una entrada del pool: qué DraftOption puede salir sorteada y con qué peso
## relativo frente al resto de las entries.
class Entry:
	extends RefCounted
	var option: DraftOption
	var weight: float

	func _init(p_option: DraftOption, p_weight: float) -> void:
		option = p_option
		weight = p_weight

var _entries: Array[Entry] = []

func _init(p_entries: Array[Entry] = []) -> void:
	_entries = p_entries.duplicate()

## Sortea count opciones con reemplazo (la misma opción puede repetirse
## entre las devueltas, no hay requisito de unicidad) mediante selección por
## ruleta ponderada. rng se recibe como parámetro explícito, nunca
## randi()/randf() global, para que el sorteo sea determinista y testeable
## headless — mismo criterio que CombatSimulation.advance(delta) recibe su
## delta explícito.
func draw_options(count: int, rng: RandomNumberGenerator) -> Array[DraftOption]:
	var total_weight: float = 0.0
	for entry in _entries:
		total_weight += entry.weight
	var result: Array[DraftOption] = []
	for i in count:
		var roll: float = rng.randf_range(0.0, total_weight)
		var cumulative: float = 0.0
		for entry in _entries:
			cumulative += entry.weight
			if roll < cumulative:
				result.append(entry.option)
				break
	return result
