extends Node2D

@export
var _eggs_to_crack: int = 4

var _eggs_cracked: int = 0

@export
var player: Node

var _label_tween: Tween

## Seconds the action must stay released after a round before another can start.
const RESTART_DELAY := 0.5

var _player_in_range = false

## Counts down while no input arrives after a round. Leftover taps keep it
## alive, so they cannot chain rounds and re-freeze the player.
var _restart_lock := 0.0

@export var recipe : Recipe

signal eggs_cracked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MiniGame.visible = false
	$Eggs.visible = false
	$MiniGame.connect("egg_cracked", _egg_cracked)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_restart_lock(delta)
	var can_crack: bool = recipe != null and InventorySingleton.hasRecipeIngredients(recipe)
	if _player_in_range and _restart_lock <= 0.0 and not $MiniGame.started:
		if (Input.is_action_just_pressed("action_command") && can_crack):
			InventorySingleton.RemoveByRecipe(recipe)
			$MiniGame.start()
			$MiniGame.visible = true
			# The player is frozen once per round; _stop_minigame() unfreezes.
			if player != null:
				player.freeze()
	if $MiniGame.started:
		$Eggs.visible = true
		$InteractionElement.visible = false
	else:
		# The glow only marks the station when an egg can actually be cracked.
		$InteractionElement.visible = can_crack


# Keeps the restart lock alive while the action is still held/tapped.
func _update_restart_lock(delta: float) -> void:
	if _restart_lock <= 0.0:
		return
	if Input.is_action_pressed("action_command"):
		_restart_lock = RESTART_DELAY
	else:
		_restart_lock -= delta


# Escape aborts a running round. Without this there was no way out of the
# mini-game until the last egg was cracked, so the frozen player could be stuck.
func _unhandled_input(event: InputEvent) -> void:
	if $MiniGame.started and event.is_action_pressed("ui_cancel"):
		_refund_recipe()
		_stop_minigame()
		get_viewport().set_input_as_handled()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false

func _egg_cracked(amount: int):
	$Label.text = "Eggs cracked: " + str(amount)
	$Label.visible = true
	_pop_label()
	
	if amount >= _eggs_to_crack:
		_stop_minigame()
		eggs_cracked.emit()
		InventorySingleton.addAmount(recipe.result, 1)


# Hides the mini-game and unfreezes the player. The restart lock keeps leftover
# taps from immediately starting (and freezing) another round.
func _stop_minigame() -> void:
	$MiniGame.stop()
	$MiniGame.visible = false
	$Label.visible = false
	$Eggs.visible = false
	_restart_lock = RESTART_DELAY
	if player != null:
		player.unfreeze()


# Hands the spent ingredients back when the player aborts a round early.
func _refund_recipe() -> void:
	if recipe == null:
		return
	for ingredient in recipe.incredients:
		InventorySingleton.addAmount(ingredient, 1)


# Quick scale pop so it's obvious the counter updated.
func _pop_label() -> void:
	if _label_tween and _label_tween.is_valid():
		_label_tween.kill()

	var label: Label = $Label
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE

	_label_tween = label.create_tween()
	_label_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_label_tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.12)
	_label_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_label_tween.tween_property(label, "scale", Vector2.ONE, 0.25)
