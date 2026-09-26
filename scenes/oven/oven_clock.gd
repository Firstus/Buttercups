class_name OvenClock
extends Node2D

## Placeholder analog clock drawn with vector primitives.
## The hand makes one full turn per bake, stepping once per tick.
## To use real art later, remove the _draw() override and add a Sprite2D face
## plus a Node2D hand pivot instead; oven.gd only calls set_progress().

## Radius of the clock face in pixels.
@export var radius: float = 26.0
## Number of visible steps the hand makes per full turn.
@export var total_ticks: int = 30

const _FACE_COLOR := Color(0.98, 0.97, 0.93)
const _RIM_COLOR := Color(0.2, 0.19, 0.23)
const _TICK_COLOR := Color(0.45, 0.43, 0.5)
const _HAND_COLOR := Color(0.78, 0.26, 0.28)
const _ARC_COLOR := Color(0.85, 0.3, 0.32, 0.55)

var _tick: int = 0


func _ready() -> void:
	# Small pop when the clock appears.
	scale = Vector2(0.4, 0.4)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)


## 0.0 = just started, 1.0 = bake finished. Driven by the oven.
func set_progress(progress: float) -> void:
	var tick := clampi(floori(clampf(progress, 0.0, 1.0) * total_ticks), 0, total_ticks)
	if tick == _tick:
		return
	_tick = tick
	queue_redraw()


func _draw() -> void:
	# Progress angle in radians, clockwise from 12 o'clock. Positive rotation
	# is clockwise in Godot's 2D space because +Y points down.
	var angle := TAU * (float(_tick) / float(total_ticks))

	draw_circle(Vector2.ZERO, radius, _FACE_COLOR)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, _RIM_COLOR, 2.0, true)

	# Clock marks at every full hour.
	for i in 12:
		var mark_angle := TAU * (float(i) / 12.0)
		var dir := Vector2(sin(mark_angle), -cos(mark_angle))
		draw_line(dir * radius * 0.84, dir * radius * 0.98, _TICK_COLOR, 2.0, true)

	# Progress arc between 12 o'clock and the hand.
	if _tick > 0:
		draw_arc(Vector2.ZERO, radius * 0.72, -PI * 0.5, -PI * 0.5 + angle, 24, _ARC_COLOR, 2.0, true)

	# Hand and center pin.
	var hand_dir := Vector2(sin(angle), -cos(angle))
	draw_line(Vector2.ZERO, hand_dir * radius * 0.65, _HAND_COLOR, 2.5, true)
	draw_circle(Vector2.ZERO, radius * 0.11, _HAND_COLOR)
