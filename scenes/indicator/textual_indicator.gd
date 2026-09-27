extends CanvasLayer

## Highest opacity the indicator brightens to while breathing in and out.
@export_range(0.0, 1.0, 0.01) var max_alpha: float = 1.0
## Lowest opacity the indicator fades to while breathing in and out.
@export_range(0.0, 1.0, 0.01) var min_alpha: float = 0.45
## Duration of one full breath (out and in), in seconds.
@export var breath_duration: float = 2.5

@onready var panel: PanelContainer = $PanelContainer

var _breath_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_breathing()


# Fades the panel and its text in and out forever, without touching their scale.
func _start_breathing() -> void:
	if _breath_tween and _breath_tween.is_valid():
		_breath_tween.kill()

	panel.modulate.a = max_alpha

	_breath_tween = create_tween().set_loops()
	_breath_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Breathe out.
	_breath_tween.tween_property(panel, "modulate:a", min_alpha, breath_duration * 0.5)

	# Breathe in.
	_breath_tween.tween_property(panel, "modulate:a", max_alpha, breath_duration * 0.5)
