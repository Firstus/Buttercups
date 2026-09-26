extends Node2D

const RESET_DELAY := 1.0

@export
var line_speed: int = 120

var started = false

var _line_vertical_dir = -1
var _eggs_cracked = 0
var _is_paused := false
var _pause_timer := 0.0

signal egg_cracked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Line2D.global_position.y = $StopTop.global_position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if started:
		if _is_paused:
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_reset_line()
			return

		$Line2D.global_position.y += line_speed * delta * _line_vertical_dir
		
		if $Line2D.global_position.y >= $StopBottom.global_position.y:
			$Line2D.global_position.y = $StopBottom.global_position.y
			_line_vertical_dir = -1
		if $Line2D.global_position.y <= $StopTop.global_position.y:
			$Line2D.global_position.y = $StopTop.global_position.y
			_line_vertical_dir = 1
		
		if Input.is_action_just_pressed("action_command"):
			var stopped_y: float = $Line2D.global_position.y
			if stopped_y <= $ZoneBottom.global_position.y and stopped_y >= $ZoneTop.global_position.y:
				_eggs_cracked += 1
				egg_cracked.emit(_eggs_cracked)
			_is_paused = true
			_pause_timer = RESET_DELAY


func _reset_line() -> void:
	_is_paused = false
	_line_vertical_dir = 1
	$Line2D.global_position.y = $StopTop.global_position.y
