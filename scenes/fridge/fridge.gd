extends Area2D

const RECIPE_DIR := "res://assets/Recipes"
# TODO: Replace with real unlock progress once crafting/progression exists.
const ENABLED_RECIPE_PATHS := ["res://assets/Recipes/Butterkeks.tres"]

@export var player: Node

@onready var _menu: FridgeMenu = $Menu

# TODO: Replace with the fridge's real storage once it exists.
var _contents: Dictionary[Item, int] = {
	preload("res://assets/Items/Mehl.tres") as Item: 3,
	preload("res://assets/Items/Backpulver.tres") as Item: 1,
	preload("res://assets/Items/Zucker.tres") as Item: 2,
	preload("res://assets/Items/Ei.tres") as Item: 4,
	preload("res://assets/Items/Butter.tres") as Item: 2,
	preload("res://assets/Items/Blaubeeren.tres") as Item: 5,
}

var _recipes: Array[Recipe] = []
var _player_in_range := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_menu.recipe_selected.connect(_on_recipe_selected)
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_load_recipes()
	# The player can already be standing in the area when this scene loads.
	if _is_player_inside():
		_show_prompt(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_command"):
		if _menu.is_open():
			_close_menu()
		elif _player_in_range:
			_open_menu()
		get_viewport().set_input_as_handled()
	elif _menu.is_open() and event.is_action_pressed("ui_cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _open_menu() -> void:
	if _menu.is_open():
		return
	_menu.open(_contents, _recipes, _is_recipe_enabled)
	$Label.visible = false
	if player != null:
		player.freeze()


func _close_menu() -> void:
	_menu.close()
	$Label.visible = _player_in_range
	if player != null:
		player.unfreeze()


func _on_recipe_selected(_recipe: Recipe) -> void:
	# TODO: Feed the selected recipe into the crafting system once it exists.
	pass


# TODO: Replace with real unlock progress.
func _is_recipe_enabled(recipe: Recipe) -> bool:
	return ENABLED_RECIPE_PATHS.has(recipe.resource_path)


func _load_recipes() -> void:
	_recipes.clear()
	var dir := DirAccess.open(RECIPE_DIR)
	if dir == null:
		push_warning("Fridge: cannot open recipe folder '%s'" % RECIPE_DIR)
		return
	for file_name in dir.get_files():
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue
		var recipe := load(RECIPE_DIR.path_join(file_name)) as Recipe
		if recipe != null:
			_recipes.append(recipe)
	_recipes.sort_custom(_sort_recipes_by_name)


func _sort_recipes_by_name(a: Recipe, b: Recipe) -> bool:
	return a.result.name < b.result.name


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if not _menu.is_open():
			_show_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if _menu.is_open():
			_close_menu()
		else:
			_show_prompt(false)


func _is_player_inside() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _show_prompt(is_visible: bool) -> void:
	$Label.visible = is_visible
