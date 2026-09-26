extends Node2D

@export
var _eggs_to_crack: int = 4

var _eggs_cracked: int = 0

@export
var player: Node

var _label_tween: Tween

var _player_in_range = false

@export var recipe : Recipe

signal eggs_cracked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MiniGame.visible = false
	$Eggs.visible = false
	$MiniGame.connect("egg_cracked", _egg_cracked)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _player_in_range:
		if (Input.is_action_just_pressed("action_command") && InventorySingleton.RemoveByRecipe(recipe)):
			$MiniGame.started = true
			$MiniGame.visible = true
	if $MiniGame.started:
		$Eggs.visible = true
		$InteractionElement.visible = false
		if player != null:
			player.freeze()


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
		$MiniGame.started = false
		$MiniGame.visible = false
		$Label.visible = false
		$Eggs.visible = false
		eggs_cracked.emit()
		if player != null:
			player.unfreeze()
		InventorySingleton.addAmount(recipe.result, 1)


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
