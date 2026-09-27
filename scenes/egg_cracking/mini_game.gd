extends Node2D

const RESET_DELAY := 1.0

@export
var line_speed: int = 120

var started = false

var _line_vertical_dir = -1
var _eggs_cracked = 0
var _is_paused := false
var _pause_timer := 0.0
var _reset_to_top := false
var _start_frame := -1

signal egg_cracked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Line2D.global_position.y = $StopTop.global_position.y


# Starts a fresh round: the counter restarts at zero and the press that starts
# the round is not also treated as a stop attempt.
func start() -> void:
	started = true
	_eggs_cracked = 0
	_is_paused = false
	_pause_timer = 0.0
	_reset_to_top = false
	_start_frame = Engine.get_process_frames()
	_reset_line()


# Ends the round without reporting a result. start() resets the state again.
func stop() -> void:
	started = false
	_is_paused = false
	_pause_timer = 0.0
	_reset_to_top = false


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

	$Line2D.global_position.y += line_speed * delta * _line_vertical_dir
	
	if $Line2D.global_position.y >= $StopBottom.global_position.y:
		$Line2D.global_position.y = $StopBottom.global_position.y
		_line_vertical_dir = -1
	if $Line2D.global_position.y <= $StopTop.global_position.y:
		$Line2D.global_position.y = $StopTop.global_position.y
		_line_vertical_dir = 1
	
	if Input.is_action_just_pressed("action_command") and Engine.get_process_frames() != _start_frame:
		var stopped_y: float = $Line2D.global_position.y
		var hit: bool = stopped_y <= $ZoneBottom.global_position.y and stopped_y >= $ZoneTop.global_position.y
		if hit:
			_eggs_cracked += 1
			egg_cracked.emit(_eggs_cracked)
			if not started:
				return
		# Only a hit starts the next attempt from the top. A miss continues from
		# where the line stopped, so mashing cannot keep it out of the zone.
		_reset_to_top = hit
		_is_paused = true
		_pause_timer = RESET_DELAY


func _reset_line() -> void:
	_is_paused = false
	_line_vertical_dir = 1
	$Line2D.global_position.y = $StopTop.global_position.y
