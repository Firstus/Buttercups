extends Node2D

signal knead_completed

@export
var player: Node

@export
var goal_level: int = 5

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
var _box_rest_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	knead_level = $CanvasLayer/KneadLevel
	knead_text = $CanvasLayer/VBoxContainer/RichTextLabel
	knead_box = $CanvasLayer/VBoxContainer
	_box_rest_position = knead_box.position
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	$Area2D.body_entered.connect(_on_area_2d_body_entered)
	$Area2D.body_exited.connect(_on_area_2d_body_exited)
	knead_text.bbcode_enabled = true
	knead_text.text = ""

	_update_level_label()
	
	#_start_minigame()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if not _is_active:
		if _player_in_range and event.is_action_pressed("action_command"):
			_start_minigame()
		return

	_handle_key(event.physical_keycode)


func _start_minigame() -> void:
	_is_active = true
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
	_update_level_label()
	if _knead_level >= goal_level:
		_complete_minigame()
	else:
		_pick_pattern()


func _complete_minigame() -> void:
	_is_active = false
	_current_pattern = []
	_input_index = 0
	knead_text.text = "[color=#8bc34a][b]Kneading done![/b][/color]"
	if player != null:
		player.unfreeze()
	knead_completed.emit()


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
		if not _is_active:
			knead_text.text = "Press [b]Space[/b] to knead"


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if not _is_active:
			knead_text.text = ""
