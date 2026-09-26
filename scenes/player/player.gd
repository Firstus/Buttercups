extends CharacterBody2D

## Maximum movement speed, in pixels per second.
@export var max_speed: float = 150.0
## How quickly the player reaches max speed, in pixels per second squared.
@export var acceleration: float = 700.0
## How quickly the player comes to a stop, in pixels per second squared.
@export var deceleration: float = 900.0
## Name of the animation played while the player is walking.
@export var walk_animation: StringName = &"default"

@onready var _sprite: AnimatedSprite2D = $Sprite2D

var _frozen: bool = false

func _physics_process(delta: float) -> void:
	if _frozen:
		return

	var direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	_update_animation(direction)

	if direction.is_zero_approx():
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		var target_velocity := direction * max_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)

	move_and_slide()

## Shows the first frame while standing still and plays the walk cycle while moving.
func _update_animation(direction: Vector2) -> void:
	if direction.is_zero_approx():
		if _sprite.is_playing():
			_sprite.stop()
		_sprite.frame = 0
		return

	# Mirror the sprite while walking left so the character faces that way.
	if not is_zero_approx(direction.x):
		_sprite.flip_h = direction.x < 0.0

	if not _sprite.is_playing():
		_sprite.play(walk_animation)

func freeze():
	_frozen = true
	velocity = Vector2.ZERO
	_update_animation(Vector2.ZERO)

func unfreeze():
	_frozen = false
