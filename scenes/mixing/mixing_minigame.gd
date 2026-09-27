extends Node

const RESET_DELAY := 1.0
const FILL_INTERVAL := 0.8
const CHECK_DELAY := 1.5

@onready var _label: Label = $Label
@onready var _goalLabel: Label = $Goal


@export
var _sugar_required: float = 20.0
@export
var _flour_required: float = 70.0
@export
var _bakingpowder_required: float = 10.0

var _current_amount : float
var _fill_amount : float
var _current_ingredient : int
var _check_timer : float

var _start_amount_check = false
var started = false
var _current_delay = FILL_INTERVAL

signal mix_complete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_label.add_theme_color_override("font_color", Color.BLACK)
	_current_ingredient = 0.0
	_current_amount = 0.0
	_goalLabel.text = "Required: \n" + str(_sugar_required)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if started:
		if _current_delay > 0.0:
			_current_delay -= delta
		else:
			if(Input.is_action_just_pressed("action_command")):
				_start_amount_check = false
				_check_timer = CHECK_DELAY
				_current_amount += snappedf(randf_range(0.1, 0.5), 0.1)
			elif(Input.is_action_pressed("action_command")):
				_start_amount_check = false
				_check_timer = CHECK_DELAY
				_fill_amount += snappedf(randf_range(0.5, 2.0), 0.1)
				_current_amount += _fill_amount
			
			_current_delay = FILL_INTERVAL
		if(Input.is_action_just_released("action_command")):
			_start_amount_check = true
			_fill_amount = 0.0
		
		_update_scale()
		if(_start_amount_check):
			_check_timer -= delta
	
		if (not Input.is_action_pressed("action_command") && _check_timer <= 0.0):
			match(_current_ingredient):
				0: 
					if(_current_amount <= _sugar_required * 1.1 and 
						_current_amount >= _sugar_required * 0.9):
						_current_amount = 0.0
						_current_ingredient += 1
						_update_required_label(_flour_required)
					elif(_current_amount > _sugar_required * 1.1):
						_current_amount = 0.0
				1:	
					if(_current_amount <= _flour_required * 1.1 and 
						_current_amount >= _flour_required * 0.9):
						_current_amount = 0.0
						_current_ingredient += 1
						_update_required_label(_bakingpowder_required)
					elif(_current_amount > _flour_required * 1.1):
						_current_amount = 0.0
				2: 	
					if(_current_amount <= _bakingpowder_required * 1.1 and 
						_current_amount >= _bakingpowder_required * 0.9):
						_current_amount = 0.0
						_end_minigame()
					elif(_current_amount > _bakingpowder_required * 1.1):
						_current_amount = 0.0
		if(_check_timer <= 0.0):
			_check_timer = CHECK_DELAY

func _end_minigame() -> void:
	mix_complete.emit()

func _update_scale() -> void:
	_label.text = str(_current_amount)
	
func _update_required_label(amount: float) -> void:
	_goalLabel.text = "Required: \n" + str(amount)
