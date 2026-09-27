extends Node2D

@export
var _eggs_to_crack: int = 4

var _eggs_cracked: int = 0

@export
var player: Node

var _label_tween: Tween
var _egg_fade_tween: Tween

## Seconds the action must stay released after a round before another can start.
const RESTART_DELAY := 0.5

## Seconds the cracked eggs stay visible after the last one before fading.
const EGG_HOLD_DELAY := 0.4

## Seconds the eggs take to fade out at the end of a round.
const EGG_FADE_DURATION := 0.5

## Texture the eggs switch to one by one, in scene order.
const CRACKED_EGG_TEXTURE := preload("res://assets/Grafiken/cracked_egg.png")

var _player_in_range = false

## Counts down while no input arrives after a round. Leftover taps keep it
## alive, so they cannot chain rounds and re-freeze the player.
var _restart_lock := 0.0

@export var recipe : Recipe

signal eggs_cracked

## The egg sprites in scene order, with their whole-egg look cached so a new
## round can restore them.
var _egg_sprites: Array[Sprite2D] = []
var _egg_whole_textures: Array[Texture2D] = []
var _egg_base_scales: Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MiniGame.visible = false
	$Eggs.visible = false
	$MiniGame.connect("egg_cracked", _egg_cracked)
	for child in $Eggs.get_children():
		var egg := child as Sprite2D
		_egg_sprites.append(egg)
		_egg_whole_textures.append(egg.texture)
		_egg_base_scales.append(egg.scale)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_restart_lock(delta)
	var can_crack: bool = recipe != null and InventorySingleton.hasRecipeIngredients(recipe)
	if _player_in_range and _restart_lock <= 0.0 and not $MiniGame.started:
		if (Input.is_action_just_pressed("action_command") && can_crack):
			InventorySingleton.RemoveByRecipe(recipe)
			_reset_eggs()
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
	_crack_egg(amount - 1)
	
	if amount >= _eggs_to_crack:
		_stop_minigame()
		_fade_eggs_out()
		eggs_cracked.emit()
		InventorySingleton.addAmount(recipe.result, 1)


# Stops the round and unfreezes the player. The restart lock keeps leftover
# taps from immediately starting (and freezing) another round. The eggs are
# faded out separately so the last crack stays visible a moment.
func _stop_minigame() -> void:
	$MiniGame.stop()
	$MiniGame.visible = false
	$Label.visible = false
	_restart_lock = RESTART_DELAY
	if player != null:
		player.unfreeze()


# Swaps one egg for the cracked texture, in scene order, and pops it.
func _crack_egg(index: int) -> void:
	if index < 0 or index >= _egg_sprites.size():
		return
	var egg: Sprite2D = _egg_sprites[index]
	egg.texture = CRACKED_EGG_TEXTURE
	var base: Vector2 = _egg_base_scales[index]
	var tween := egg.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(egg, "scale", base * 1.3, 0.12)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(egg, "scale", base, 0.25)


# A new round always starts with four whole, fully opaque eggs.
func _reset_eggs() -> void:
	if _egg_fade_tween and _egg_fade_tween.is_valid():
		_egg_fade_tween.kill()
	$Eggs.modulate.a = 1.0
	for i in _egg_sprites.size():
		_egg_sprites[i].texture = _egg_whole_textures[i]
		_egg_sprites[i].scale = _egg_base_scales[i]


# The cracked eggs linger briefly at the end of a round, then fade out.
func _fade_eggs_out() -> void:
	if _egg_fade_tween and _egg_fade_tween.is_valid():
		_egg_fade_tween.kill()
	_egg_fade_tween = $Eggs.create_tween()
	_egg_fade_tween.tween_interval(EGG_HOLD_DELAY)
	_egg_fade_tween.tween_property($Eggs, "modulate:a", 0.0, EGG_FADE_DURATION)
	_egg_fade_tween.tween_callback(_hide_eggs)


func _hide_eggs() -> void:
	# A new round may have started in the meantime; its eggs must stay visible.
	if not $MiniGame.started:
		$Eggs.visible = false


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
