extends Node2D

@export
var player : Node

var player_in_range = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MiniGame.visible = false
	$MiniGame.connect("mix_complete", _mix_complete)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		
func _on_are_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range:
		if Input.is_action_just_pressed("action_command"):
			$MiniGame.started = true
			$MiniGame.visible = true
	if $MiniGame.started:
		if player != null:
			player.freeze()

#TODO add created item to inventory
func _mix_complete() -> void:
	$MiniGame.visible = false
	$MiniGame.started = false
