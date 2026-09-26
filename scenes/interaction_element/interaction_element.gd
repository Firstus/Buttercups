extends Node2D

## Lowest opacity the sprite fades to while breathing in and out.
@export_range(0.0, 1.0, 0.01) var min_alpha: float = 0.45
## Highest opacity the sprite brightens to while breathing in and out.
@export_range(0.0, 1.0, 0.01) var max_alpha: float = 1.0
## Duration of one full breath (out and in), in seconds.
@export var breath_duration: float = 2.5

@onready var sprite: Sprite2D = $Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_breathing()


# Fades the sprite's opacity in and out forever, without touching its size.
func _start_breathing() -> void:
	sprite.modulate.a = max_alpha

	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Breathe out.
	tween.tween_property(sprite, "modulate:a", min_alpha, breath_duration * 0.5)

	# Breathe in.
	tween.tween_property(sprite, "modulate:a", max_alpha, breath_duration * 0.5)
