extends Control
## Composition root de la pantalla de inicio. No conoce nada del dominio del
## juego (InventoryGrid, CombatSimulation, etc.) ni de Scripts/Main/main.gd:
## solo sabe que existe un archivo de escena de gameplay al que navegar.
## Configuración y Galería quedan deshabilitados (sin handler conectado)
## porque no existe todavía ningún sistema de configuración ni de galería
## que mostrar detrás de esos botones.

@onready var _start_button: Button = $VBoxContainer/StartButton
@onready var _exit_button: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/overworld/Overworld.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
