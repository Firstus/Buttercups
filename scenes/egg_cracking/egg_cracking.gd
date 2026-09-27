extends Node2D

signal eggs_cracked

## Eggs that must be cracked to finish a round.
@export
var _eggs_to_crack: int = 4

## Node frozen while a round runs. Falls back to the "player" group when unset.
@export
var player: Node

## Recipe cracked here. A round costs its ingredients and yields its result.
@export var recipe : Recipe

## Seconds after a round before another one can start.
const RESTART_DELAY := 0.5

## Seconds the cracked eggs stay visible after the last one before fading.
const EGG_HOLD_DELAY := 0.4

## Seconds the eggs take to fade out at the end of a round.
const EGG_FADE_DURATION := 0.5

## Texture the eggs switch to one by one, in scene order.
const CRACKED_EGG_TEXTURE := preload("res://assets/Grafiken/cracked_egg.png")

## Station lifecycle: out of range, able to start, round running, or cooling
## down after a round. All transitions go through _begin_round()/_end_round().
enum State { IDLE, READY, PLAYING, COOLDOWN }

var _state: State = State.IDLE
var _player_in_range := false

## Recipe of the running round, cached so a mid-round export change cannot
## affect the reward.
var _round_recipe: Recipe = null

## Whether this station froze the player, so freeze/unfreeze always pairs up.
var _player_frozen := false

var _cooldown := 0.0

## The egg sprites in scene order, with their whole-egg look cached so a new
## round can restore them.
var _egg_sprites: Array[Sprite2D] = []
var _egg_whole_textures: Array[Texture2D] = []
var _egg_base_scales: Array[Vector2] = []

var _egg_fade_tween: Tween

@onready var _indicator: CanvasLayer = $Indicator

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


# Single input owner for the round: the press that starts it only ever reaches
# the READY branch, so the mini-game can never misread it as a stop attempt.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("action_command"):
		return

	match _state:
		State.READY:
			if not _can_crack():
				return
			get_viewport().set_input_as_handled()
			_begin_round()
		State.PLAYING:
			get_viewport().set_input_as_handled()
			if $MiniGame.press():
				_end_round()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _state == State.COOLDOWN:
		_cooldown -= delta
		if _cooldown <= 0.0:
			_enter_ready_or_idle()

	# The glow and the press-space prompt only mark the station while an egg
	# can actually be cracked and no round is running.
	var can_crack: bool = _state != State.PLAYING and _can_crack()
	$InteractionElement.visible = can_crack
	_indicator.visible = can_crack and _player_in_range


# A station freed mid-round must not leave the player frozen behind.
func _exit_tree() -> void:
	_set_player_frozen(false)


func _can_crack() -> bool:
	return recipe != null and InventorySingleton.hasRecipeIngredients(recipe)


# Starts a round: ingredients are paid up front, the player is frozen and the
# mini-game runs until it reports the last egg cracked.
func _begin_round() -> void:
	if _state == State.PLAYING:
		return
	if not InventorySingleton.RemoveByRecipe(recipe):
		return

	_round_recipe = recipe
	_state = State.PLAYING
	_reset_eggs()
	$MiniGame.visible = true
	$MiniGame.start(_eggs_to_crack)
	_set_player_frozen(true)


# Single, idempotent exit point of a round.
func _end_round() -> void:
	if _state != State.PLAYING:
		return

	_state = State.COOLDOWN
	_cooldown = RESTART_DELAY
	$MiniGame.stop()
	$MiniGame.visible = false
	_fade_eggs_out()
	_set_player_frozen(false)
	if _round_recipe != null:
		InventorySingleton.addAmount(_round_recipe.result, 1)
		_round_recipe = null
	eggs_cracked.emit()


func _enter_ready_or_idle() -> void:
	_state = State.READY if _player_in_range else State.IDLE


# Freeze and unfreeze are always issued from here, never from the mini-game,
# so no round exit path can leave the player frozen.
func _set_player_frozen(is_frozen: bool) -> void:
	if _player_frozen == is_frozen:
		return
	_player_frozen = is_frozen

	if not is_instance_valid(player) and is_inside_tree():
		player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	if is_frozen:
		player.freeze()
	else:
		player.unfreeze()


func _egg_cracked(amount: int) -> void:
	_crack_egg(amount - 1)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	if _state == State.IDLE:
		_state = State.READY


func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	if _state == State.READY:
		_state = State.IDLE


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
	$Eggs.visible = true
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
	if _state != State.PLAYING:
		$Eggs.visible = false
