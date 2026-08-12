extends Control
## Composition root de la pantalla de overworld. No conoce nada del dominio
## del juego (InventoryGrid, CombatSimulation, etc.) ni de
## Scripts/Main/main.gd: solo sabe que existe un archivo de escena de
## gameplay al que navegar y uno de menú al que volver. Los tres botones de
## nivel son idénticos a propósito: esta fase solo prueba el flujo de
## escenas (Menú → Overworld → Batalla → volver al Overworld), todavía sin
## contenido propio por nivel ni noción de nivel bloqueado/desbloqueado.

@onready var _level_1_button: Button = $VBoxContainer/Level1Button
@onready var _level_2_button: Button = $VBoxContainer/Level2Button
@onready var _level_3_button: Button = $VBoxContainer/Level3Button
@onready var _back_button: Button = $BackButton

func _ready() -> void:
	_level_1_button.pressed.connect(_on_level_pressed)
	_level_2_button.pressed.connect(_on_level_pressed)
	_level_3_button.pressed.connect(_on_level_pressed)
	_back_button.pressed.connect(_on_back_pressed)

func _on_level_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
