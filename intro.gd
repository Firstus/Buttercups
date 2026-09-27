extends Node2D

signal start_pressed

const KITCHEN_SCENE := "res://scenes/kitchen/kitchen.tscn"

## Index of the snippet after which the intact factory fades in as background.
const FACTORY_REVEAL_AFTER := 0
## Index of the snippet after which the background changes to the destroyed factory.
const DESTROYED_REVEAL_AFTER := 3

## Seconds between each typed character.
@export var char_delay: float = 0.04
## Seconds a fully typed text stays on screen before fading out automatically.
@export var read_delay: float = 2.5
## Duration of the fade out / fade in.
@export var fade_time: float = 0.4
## Duration of the background fades (black -> factory, factory -> destroyed factory).
@export var background_fade_time: float = 0.8
## Seconds the freshly faded-in background stays sharp before it is blurred.
@export var clear_delay: float = 1.0
## Duration of the sharp -> blurred background transition.
@export var blur_duration: float = 0.6
## Lowest alpha of the "press space" label while breathing.
@export var breathe_alpha: float = 0.35
## Seconds for one direction of the breathing animation.
@export var breathe_time: float = 1.2

var _intro_text: Array[String] = [
	"Es ist 2026 in Hannover, Ende Oktober und Halloween steht vor der Tür.",
	"Jedoch...",
	"ist ein schreckliches Unglück in der Stadt vorgefallen.",
	"Die Fabrik des Lebenselixiers, das weltbekannte Wahrzeichens Hannovers, die des Butterkeks steht lichterloh in Flammen.",
	"Trauer befällt die Stadt.",
	"Was wird denn jetzt aus Halloween, ein Fest, in dem Butterkekse so eine große Rolle spielen?",
	"Mitten in den Trümmern der zerstörten Fabrik tut sich ein Held auf.",
	"Zu Lebzeiten, kontinuierlich Mitarbeiter des Monats. Aber auch nach dem Tod gewillt, den Hannoveranern ihre Butterkekse zu backen."
]

enum State {
	TYPING,
	READING,
	FADING_OUT,
	BACKGROUND,
	DONE
}

enum BackgroundBeat {
	FACTORY,
	DESTROYED
}

var _index: int = 0
var _char_progress: int = 0
var _char_timer: float = 0.0
var _read_timer: float = 0.0
var _state: State = State.TYPING
var _beat: BackgroundBeat = BackgroundBeat.FACTORY
var _blur_target: Sprite2D

var _label: Label
var _start_label: Label
var _black_rect: ColorRect
var _factory_intact: Sprite2D
var _factory_destroyed: Sprite2D
var _tween: Tween
var _breath_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_label = $Label
	_start_label = $StartLabel
	_black_rect = $ColorRect
	_factory_intact = $FactoryIntact
	_factory_destroyed = $FactoryDestroyed
	_start_label.visible = false
	start_pressed.connect(_on_start_pressed)
	_begin_text(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match _state:
		State.TYPING:
			_type_next(delta)
		State.READING:
			_read_timer -= delta
			if _read_timer <= 0.0:
				_start_fade_out()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("action_command"):
		return

	match _state:
		State.TYPING:
			_complete_text()
		State.READING:
			_advance()
		State.FADING_OUT:
			_advance()
		State.BACKGROUND:
			_skip_background()
		State.DONE:
			start_pressed.emit()


func _type_next(delta: float) -> void:
	_char_timer -= delta
	var text := _current_text()
	if _char_progress < text.length() and _char_timer <= 0.0:
		while _char_progress < text.length() and _char_timer <= 0.0:
			_char_progress += 1
			_char_timer += char_delay
		_label.text = text.substr(0, _char_progress)

	if _char_progress >= text.length():
		_state = State.READING
		_read_timer = read_delay


func _complete_text() -> void:
	_char_progress = _current_text().length()
	_label.text = _current_text()
	_state = State.READING
	_read_timer = read_delay


func _advance() -> void:
	_kill_tween()
	_index += 1
	_enter_snippet(false)


func _on_faded_out() -> void:
	_index += 1
	_enter_snippet(true)


func _enter_snippet(with_fade: bool) -> void:
	if _index >= _intro_text.size():
		_finish_intro()
	elif _index == FACTORY_REVEAL_AFTER + 1:
		_play_background_beat(BackgroundBeat.FACTORY)
	elif _index == DESTROYED_REVEAL_AFTER + 1:
		_play_background_beat(BackgroundBeat.DESTROYED)
	else:
		_begin_text(with_fade)


# Hides the text and directs the background: the new image fades in sharp,
# stays sharp for a moment, is blurred and only then the next text starts.
func _play_background_beat(beat: BackgroundBeat) -> void:
	_kill_tween()
	_state = State.BACKGROUND
	_beat = beat
	_blur_target = _factory_destroyed if beat == BackgroundBeat.DESTROYED else _factory_intact
	_label.text = ""
	_label.modulate.a = 0.0

	var material := _blur_target.material as ShaderMaterial
	_tween = create_tween()
	if beat == BackgroundBeat.DESTROYED:
		_tween.tween_property(_factory_destroyed, "modulate:a", 1.0, background_fade_time)
	else:
		_tween.tween_property(_black_rect, "modulate:a", 0.0, background_fade_time)
	_tween.tween_interval(clear_delay)
	_tween.tween_property(material, "shader_parameter/blur_amount", 1.0, blur_duration)
	_tween.tween_callback(_begin_text.bind(true))


func _skip_background() -> void:
	_kill_tween()
	_black_rect.modulate.a = 0.0
	if _beat == BackgroundBeat.DESTROYED:
		_factory_destroyed.modulate.a = 1.0
	var material := _blur_target.material as ShaderMaterial
	material.set_shader_parameter("blur_amount", 1.0)
	_begin_text(true)


func _begin_text(with_fade: bool) -> void:
	_label.text = ""
	_label.visible = true
	_char_progress = 0
	_char_timer = 0.0
	_state = State.TYPING
	if with_fade:
		_label.modulate.a = 0.0
		_tween = create_tween()
		_tween.tween_property(_label, "modulate:a", 1.0, fade_time)
	else:
		_label.modulate.a = 1.0


func _start_fade_out() -> void:
	_state = State.FADING_OUT
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(_on_faded_out)


func _finish_intro() -> void:
	_state = State.DONE
	_kill_tween()
	_start_label.visible = true
	_start_label.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, fade_time)
	_tween.parallel().tween_property(_start_label, "modulate:a", 1.0, fade_time)
	_tween.tween_callback(_hide_label)
	_tween.tween_callback(_start_breathing)


func _hide_label() -> void:
	_label.visible = false


func _start_breathing() -> void:
	if _breath_tween and _breath_tween.is_valid():
		_breath_tween.kill()
	_breath_tween = create_tween().set_loops()
	_breath_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath_tween.tween_property(_start_label, "modulate:a", breathe_alpha, breathe_time)
	_breath_tween.tween_property(_start_label, "modulate:a", 1.0, breathe_time)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(KITCHEN_SCENE)


func _current_text() -> String:
	return _intro_text[_index]


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
