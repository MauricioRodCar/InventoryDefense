class_name DefenderView
extends Node2D
## Representación visual mínima de un Defender activo: un cuadrado en una
## posición fija. Defender no lleva posición propia (deuda conocida, ver
## notas de diseño de Battle en el README); por eso BattleView decide un
## layout propio al crearla, ajeno a la celda original del inventario.

const _SIZE: float = 16.0

func setup(world_position: Vector2) -> void:
	position = world_position
	queue_redraw()

func _draw() -> void:
	var half := _SIZE * 0.5
	draw_rect(Rect2(Vector2(-half, -half), Vector2.ONE * _SIZE), Color.SKY_BLUE, true)
