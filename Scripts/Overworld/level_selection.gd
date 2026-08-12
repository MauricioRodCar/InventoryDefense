extends Node
## Único autoload del proyecto: retiene la WaveData elegida en Overworld
## para que main.gd la lea al construir la partida. Sin esto no hay forma de
## pasar datos entre escenas con change_scene_to_file(). Puramente en
## memoria, se resetea en cada arranque de la aplicación — no hay
## persistencia todavía (ver fase 5 de este roadmap).

const WaveData = preload("res://Scripts/Gameplay/Combat/wave_data.gd")

var selected_wave_schedule: Array[WaveData] = []
