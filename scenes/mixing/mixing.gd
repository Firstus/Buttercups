extends Node2D

## Seconds the action must stay released after a round before another can start.
const RESTART_DELAY := 0.5

@export
var player : Node

@export
var recipe : Recipe

var player_in_range = false

## Counts down while no input arrives after a round. Leftover taps keep it
## alive, so they cannot chain rounds and re-freeze the player.
var _restart_lock := 0.0


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
	_update_restart_lock(delta)
	var can_mix: bool = recipe != null and InventorySingleton.hasRecipeIngredients(recipe)
	if player_in_range and _restart_lock <= 0.0 and not $MiniGame.started:
		if Input.is_action_just_pressed("action_command") && can_mix:
			InventorySingleton.RemoveByRecipe(recipe)
			$MiniGame.started = true
			$MiniGame.visible = true
			# The player is frozen once per round; _mix_complete() unfreezes.
			if player != null:
				player.freeze()
	if $MiniGame.started:
		$InteractionElement.visible = false
	else:
		# The glow only marks the station while the recipe can actually be mixed.
		$InteractionElement.visible = can_mix


# Keeps the restart lock alive while the action is still held/tapped.
func _update_restart_lock(delta: float) -> void:
	if _restart_lock <= 0.0:
		return
	if Input.is_action_pressed("action_command"):
		_restart_lock = RESTART_DELAY
	else:
		_restart_lock -= delta

#TODO add created item to inventory
func _mix_complete() -> void:
	$MiniGame.visible = false
	$MiniGame.started = false
	InventorySingleton.addAmount(recipe.result, 1)
	_restart_lock = RESTART_DELAY
	if player != null:
		player.unfreeze()
