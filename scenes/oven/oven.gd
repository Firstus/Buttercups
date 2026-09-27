extends Node2D

## Emitted when a bake starts.
signal baking_started
## Emitted when the bake timer runs out.
signal baking_finished

## Recipes the oven can bake, tried in order. The first one whose ingredients
## are in the inventory is used when the player starts a bake.
@export var recipes: Array[Recipe] = []

## Seconds the oven stays on per use.
@export var bake_time: float = 30.0

const CLOCK_SCENE := preload("res://scenes/oven/oven_clock.tscn")

@onready var _clock_spawn: Marker2D = $ClockSpawn
@onready var _indicator: CanvasLayer = $Indicator
@onready var _timer: Timer = $Timer

var _player_in_range := false
var _is_baking := false
var _baking_recipe: Recipe
var _duration := 0.0
var _clock: OvenClock


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	_timer.timeout.connect(_on_timer_timeout)


func _process(_delta: float) -> void:
	if _is_baking and _clock != null:
		_clock.set_progress(1.0 - _timer.time_left / _duration)
	# The glow and press-space prompt only show while a cookie can actually be baked.
	var can_bake := _can_bake()
	$InteractionElement.visible = can_bake and not _is_baking
	_indicator.visible = _player_in_range and can_bake and not _is_baking


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _is_baking:
		return
	if not event.is_action_pressed("action_command"):
		return

	var recipe := _get_available_recipe()
	if recipe == null:
		return

	InventorySingleton.RemoveByRecipe(recipe)
	_start_baking(recipe)
	get_viewport().set_input_as_handled()


# First configured recipe whose ingredients are in the inventory, or null.
func _get_available_recipe() -> Recipe:
	for recipe in recipes:
		if InventorySingleton.hasRecipeIngredients(recipe):
			return recipe
	return null


func _can_bake() -> bool:
	return _get_available_recipe() != null


func _start_baking(recipe: Recipe) -> void:
	_is_baking = true
	_baking_recipe = recipe
	_duration = maxf(bake_time, 0.1)
	_clock = CLOCK_SCENE.instantiate()
	_clock.position = _clock_spawn.position
	add_child(_clock)
	_timer.start(_duration)
	baking_started.emit()
	$AudioStreamPlayer2D2.play(0)


func _on_timer_timeout() -> void:
	_is_baking = false
	if _clock != null:
		_clock.queue_free()
		_clock = null
	if _baking_recipe != null:
		InventorySingleton.addAmount(_baking_recipe.result, 1)
		_baking_recipe = null
	baking_finished.emit()
	$AudioStreamPlayer2D.play(6.2)


## The oven does not freeze the player, so the clock is the only "oven is on" indicator.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
