extends CharacterBody2D

## Maximum movement speed, in pixels per second.
@export var max_speed: float = 150.0
## How quickly the player reaches max speed, in pixels per second squared.
@export var acceleration: float = 700.0
## How quickly the player comes to a stop, in pixels per second squared.
@export var deceleration: float = 900.0

var _frozen: bool = false

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	var target_velocity := direction * max_speed
	
	if _frozen:
		return

	if direction.is_zero_approx():
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)

	move_and_slide()
	
func freeze():
	_frozen = true
	velocity = Vector2.ZERO
	
func unfreeze():
	_frozen = false
