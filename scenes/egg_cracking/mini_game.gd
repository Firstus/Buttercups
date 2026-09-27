extends Node2D

const RESET_DELAY := 1.0

## Fraction of the screen height the canvas gauge fills.
const GAUGE_HEIGHT_FRACTION := 0.85

## Screen-space gap between the gauge and the right screen edge.
const GAUGE_RIGHT_MARGIN := 60.0

## Screen-space distance the gauge jolts sideways on a miss.
const MISS_SHAKE_OFFSET := 10.0

@export
var line_speed: int = 120

var started = false

var _line_vertical_dir = -1
var _eggs_cracked = 0
var _is_paused := false
var _pause_timer := 0.0
var _reset_to_top := false
var _start_frame := -1
var _shake_tween: Tween
var _gauge_base_x := 0.0

@onready var _gauge_root: Node2D = $GaugeCanvas/GaugeRoot
@onready var _line: Line2D = $GaugeCanvas/GaugeRoot/Line2D
@onready var _stop_top: Marker2D = $GaugeCanvas/GaugeRoot/StopTop
@onready var _stop_bottom: Marker2D = $GaugeCanvas/GaugeRoot/StopBottom
@onready var _zone_top: Marker2D = $GaugeCanvas/GaugeRoot/ZoneTop
@onready var _zone_bottom: Marker2D = $GaugeCanvas/GaugeRoot/ZoneBottom

signal egg_cracked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Canvas layers do not inherit their parent's visibility, so the gauge is
	# hidden explicitly until a round starts.
	_gauge_root.visible = false
	get_viewport().size_changed.connect(_layout_gauge)
	_reset_line()


# Starts a fresh round: the counter restarts at zero and the press that starts
# the round is not also treated as a stop attempt.
func start() -> void:
	started = true
	_eggs_cracked = 0
	_is_paused = false
	_pause_timer = 0.0
	_reset_to_top = false
	_start_frame = Engine.get_process_frames()
	_layout_gauge()
	_gauge_root.visible = true
	_reset_line()


# Ends the round without reporting a result. start() resets the state again.
func stop() -> void:
	started = false
	_is_paused = false
	_pause_timer = 0.0
	_reset_to_top = false
	_gauge_root.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not started:
		return

	if _is_paused:
		_pause_timer -= delta
		if _pause_timer > 0.0:
			return
		_is_paused = false
		if _reset_to_top:
			_reset_line()

	_line.position.y += line_speed * delta * _line_vertical_dir
	
	if _line.position.y >= _stop_bottom.position.y:
		_line.position.y = _stop_bottom.position.y
		_line_vertical_dir = -1
	if _line.position.y <= _stop_top.position.y:
		_line.position.y = _stop_top.position.y
		_line_vertical_dir = 1
	
	if Input.is_action_just_pressed("action_command") and Engine.get_process_frames() != _start_frame:
		var stopped_y: float = _line.position.y
		var hit: bool = stopped_y <= _zone_bottom.position.y and stopped_y >= _zone_top.position.y
		if hit:
			_eggs_cracked += 1
			egg_cracked.emit(_eggs_cracked)
			if not started:
				return
		else:
			_shake_gauge()
		# Only a hit starts the next attempt from the top. A miss continues from
		# where the line stopped, so mashing cannot keep it out of the zone.
		_reset_to_top = hit
		_is_paused = true
		_pause_timer = RESET_DELAY


# Right-aligns the gauge on the screen at the wanted height.
func _layout_gauge() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var gauge_scale: float = screen.y * GAUGE_HEIGHT_FRACTION / 128.0
	_gauge_root.scale = Vector2(gauge_scale, gauge_scale)
	# The visible bar ends at texture x 47; keep that edge a margin from the right.
	var visible_right: float = (47.5 - 32.0) * gauge_scale
	_gauge_base_x = screen.x - GAUGE_RIGHT_MARGIN - visible_right
	_gauge_root.position = Vector2(_gauge_base_x, screen.y * 0.5)


# Quick sideways jolt so a missed stop is obvious.
func _shake_gauge() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = _gauge_root.create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(_gauge_root, "position:x", _gauge_base_x + MISS_SHAKE_OFFSET, 0.05)
	_shake_tween.tween_property(_gauge_root, "position:x", _gauge_base_x - MISS_SHAKE_OFFSET, 0.1)
	_shake_tween.tween_property(_gauge_root, "position:x", _gauge_base_x, 0.05)


func _reset_line() -> void:
	_is_paused = false
	_line_vertical_dir = 1
	_line.position.y = _stop_top.position.y
