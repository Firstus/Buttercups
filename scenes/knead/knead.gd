extends Node2D

signal knead_completed

@export
var player: Node

@export
var goal_level: int = 5

## Recipe kneaded here. A round costs its ingredients and yields its result.
@export var recipe: Recipe

## Seconds the action must stay released after a round before another can start.
const RESTART_DELAY := 0.5

## Seconds the finished dough stays visible after the last knead before fading.
const DOUGH_HOLD_DELAY := 0.4

## Seconds the dough takes to fade out at the end of a round.
const DOUGH_FADE_DURATION := 0.5

const _TOKEN_KEYS := {
	"A": KEY_A,
	"D": KEY_D,
	"W": KEY_W,
	"S": KEY_S,
	"Space": KEY_SPACE
}

var _knead_level: int = 0
var _input_index: int = 0
var _is_active: bool = false
var _player_in_range: bool = false
var _current_pattern: Array = []

## Counts down while no input arrives after a round. Leftover presses keep it
## alive, so they cannot chain rounds and re-freeze the player.
var _restart_lock := 0.0

var _character_patterns = [
	["A", "D", "A", "D"],
	["Space", "W", "S", "Space"],
	["A", "W", "D", "S"],
	["W", "S", "W", "S"]
]

var knead_text: Node
var knead_level: Node
var knead_box: Node

var _shake_tween: Tween
var _dough_fade_tween: Tween
var _box_rest_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	knead_level = $CanvasLayer/KneadLevel
	knead_text = $CanvasLayer/VBoxContainer/RichTextLabel
	knead_box = $CanvasLayer/VBoxContainer
	$KneadingSprite.visible = false
	_box_rest_position = knead_box.position
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	$Area2D.body_entered.connect(_on_area_2d_body_entered)
	$Area2D.body_exited.connect(_on_area_2d_body_exited)
	knead_text.bbcode_enabled = true
	knead_text.text = ""

	_update_level_label()
	
	#_start_minigame()


# The glow only marks the station while the dough can actually be kneaded.
func _process(delta: float) -> void:
	_update_restart_lock(delta)
	if not _is_active:
		$InteractionElement.visible = _can_knead()


# Keeps the restart lock alive while the action is still held/tapped.
func _update_restart_lock(delta: float) -> void:
	if _restart_lock <= 0.0:
		return
	if Input.is_action_pressed("action_command"):
		_restart_lock = RESTART_DELAY
	else:
		_restart_lock -= delta


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if not _is_active:
		if _player_in_range and event.is_action_pressed("action_command") and _can_knead() and _restart_lock <= 0.0:
			_start_minigame()
		return

	_handle_key(event.physical_keycode)


func _can_knead() -> bool:
	return recipe != null and InventorySingleton.hasRecipeIngredients(recipe)


func _start_minigame() -> void:
	if not InventorySingleton.RemoveByRecipe(recipe):
		return
	_is_active = true
	if _dough_fade_tween and _dough_fade_tween.is_valid():
		_dough_fade_tween.kill()
	$KneadingSprite.visible = true
	$KneadingSprite.frame = 0
	$KneadingSprite.modulate.a = 1.0
	_knead_level = 0
	_update_level_label()
	$InteractionElement.visible = false
	if player != null:
		player.freeze()
	_pick_pattern()


func _pick_pattern() -> void:
	var next_pattern: Array = _character_patterns.pick_random()
	while _character_patterns.size() > 1 and next_pattern == _current_pattern:
		next_pattern = _character_patterns.pick_random()
	_current_pattern = next_pattern
	_input_index = 0
	_update_pattern_label()


func _handle_key(keycode: int) -> void:
	if not _TOKEN_KEYS.values().has(keycode):
		return

	if _TOKEN_KEYS[_current_pattern[_input_index]] != keycode:
		_input_index = 0
		_update_pattern_label()
		_shake_pattern()
		return

	_input_index += 1
	if _input_index < _current_pattern.size():
		_update_pattern_label()
		return

	_knead_level += 1
	$KneadingSprite.frame = min($KneadingSprite.frame + 1, 4)
	_update_level_label()
	if _knead_level >= goal_level:
		_complete_minigame()
	else:
		_pick_pattern()


func _complete_minigame() -> void:
	_is_active = false
	_current_pattern = []
	_input_index = 0
	InventorySingleton.addAmount(recipe.result, 1)
	knead_text.text = ""
	_restart_lock = RESTART_DELAY
	_fade_dough_out()
	if player != null:
		player.unfreeze()
	knead_completed.emit()


# The finished dough lingers briefly, then fades out like the cracked eggs.
func _fade_dough_out() -> void:
	if _dough_fade_tween and _dough_fade_tween.is_valid():
		_dough_fade_tween.kill()
	_dough_fade_tween = $KneadingSprite.create_tween()
	_dough_fade_tween.tween_interval(DOUGH_HOLD_DELAY)
	_dough_fade_tween.tween_property($KneadingSprite, "modulate:a", 0.0, DOUGH_FADE_DURATION)
	_dough_fade_tween.tween_callback(_hide_dough)


func _hide_dough() -> void:
	# A new round may have started in the meantime; its dough must stay visible.
	if not _is_active:
		$KneadingSprite.visible = false


# Shows the pattern with progress: done = green, next = yellow, upcoming = gray.
func _update_pattern_label() -> void:
	var parts: PackedStringArray = []
	for i in _current_pattern.size():
		var token: String = _current_pattern[i]
		if i < _input_index:
			parts.append("[color=#8bc34a]%s[/color]" % token)
		elif i == _input_index:
			parts.append("[color=#ffd54f][b]%s[/b][/color]" % token)
		else:
			parts.append("[color=#9e9e9e]%s[/color]" % token)
	knead_text.text = " - ".join(parts)


# Shakes the pattern display when a wrong key is pressed.
func _shake_pattern() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		knead_box.position = _box_rest_position

	var strength := 12.0
	_shake_tween = create_tween()
	for _i in 3:
		_shake_tween.tween_property(knead_box, "position", _box_rest_position + Vector2(strength, 0), 0.04)
		_shake_tween.tween_property(knead_box, "position", _box_rest_position - Vector2(strength, 0), 0.04)
	_shake_tween.tween_property(knead_box, "position", _box_rest_position, 0.05)


func _update_level_label() -> void:
	knead_level.text = "Knetlevel: %d / %d" % [_knead_level, goal_level]


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if not _is_active and _can_knead():
			knead_text.text = "Press [b]Space[/b] to knead"


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if not _is_active:
			knead_text.text = ""
