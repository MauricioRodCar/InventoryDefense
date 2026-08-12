extends Control
## Composition root de la pantalla de overworld. No conoce nada del dominio
## del juego (InventoryGrid, CombatSimulation, etc.) ni de
## Scripts/Main/main.gd: solo sabe construir un calendario de waves por nodo
## de nivel, entregárselo a LevelSelection y navegar a la escena de gameplay
## o a la de menú. Cada nodo de nivel ahora carga su propio calendario
## (más waves, más enemigos por wave a medida que sube el nivel) en vez de
## los tres botones idénticos de la fase anterior.

const EnemyData = preload("res://Scripts/Gameplay/Combat/enemy_data.gd")
const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")

@onready var _level_1_button: Button = $VBoxContainer/Level1Button
@onready var _level_2_button: Button = $VBoxContainer/Level2Button
@onready var _level_3_button: Button = $VBoxContainer/Level3Button
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	_level_1_button.pressed.connect(_on_level_pressed.bind(_build_level_1_wave_schedule()))
	_level_2_button.pressed.connect(_on_level_pressed.bind(_build_level_2_wave_schedule()))
	_level_3_button.pressed.connect(_on_level_pressed.bind(_build_level_3_wave_schedule()))
	_back_button.pressed.connect(_on_back_pressed)

func _on_level_pressed(wave_schedule: Array[WaveData]) -> void:
	LevelSelection.selected_wave_schedule = wave_schedule
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

## Nivel 1: igual al calendario de sandbox que ya usaba main.gd sin
## diferenciar por nivel (dos waves: 2 goblins, 3 goblins) — el punto de
## partida de la progresión de dificultad.
func _build_level_1_wave_schedule() -> Array[WaveData]:
	var goblin := EnemyData.new(&"goblin", 60, 20.0)
	var first_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
	])
	var second_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
	])
	return [first_wave, second_wave]

## Nivel 2: tres waves de 3/4/5 goblins — más largo y más denso que el
## Nivel 1, valores de placeholder que solo buscan demostrar progresión.
func _build_level_2_wave_schedule() -> Array[WaveData]:
	var goblin := EnemyData.new(&"goblin", 60, 20.0)
	var first_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
	])
	var second_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
		WaveData.SpawnEntry.new(6.0, goblin),
	])
	var third_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
		WaveData.SpawnEntry.new(6.0, goblin),
		WaveData.SpawnEntry.new(8.0, goblin),
	])
	return [first_wave, second_wave, third_wave]

## Nivel 3: tres waves de 5/6/7 goblins — el más difícil de los tres,
## mismo criterio de progresión que Nivel 2.
func _build_level_3_wave_schedule() -> Array[WaveData]:
	var goblin := EnemyData.new(&"goblin", 60, 20.0)
	var first_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
		WaveData.SpawnEntry.new(6.0, goblin),
		WaveData.SpawnEntry.new(8.0, goblin),
	])
	var second_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
		WaveData.SpawnEntry.new(6.0, goblin),
		WaveData.SpawnEntry.new(8.0, goblin),
		WaveData.SpawnEntry.new(10.0, goblin),
	])
	var third_wave := WaveData.new([
		WaveData.SpawnEntry.new(0.0, goblin),
		WaveData.SpawnEntry.new(2.0, goblin),
		WaveData.SpawnEntry.new(4.0, goblin),
		WaveData.SpawnEntry.new(6.0, goblin),
		WaveData.SpawnEntry.new(8.0, goblin),
		WaveData.SpawnEntry.new(10.0, goblin),
		WaveData.SpawnEntry.new(12.0, goblin),
	])
	return [first_wave, second_wave, third_wave]
