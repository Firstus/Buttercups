class_name FridgeMenu
extends CanvasLayer

## Emitted when an enabled recipe is selected in the menu.
signal recipe_selected(recipe: Recipe)

const ITEM_SLOT_SCENE := preload("res://scenes/fridge/fridge_item_slot.tscn")

@onready var _contents_grid: GridContainer = $Panel/Margin/VBox/Body/ContentsColumn/ContentsGrid
@onready var _recipe_list: ItemList = $Panel/Margin/VBox/Body/RecipesColumn/RecipeList
@onready var _details: RichTextLabel = $Panel/Margin/VBox/Body/RecipesColumn/Details

var _recipes: Array[Recipe] = []


func _ready() -> void:
	visible = false
	_recipe_list.item_selected.connect(_on_recipe_item_selected)
	_show_default_details()


func is_open() -> bool:
	return visible


## Shows the menu with the given fridge contents and recipes.
## `is_recipe_enabled` is called with each recipe to decide if it can be selected.
func open(contents: Dictionary[Item, int], recipes: Array[Recipe], is_recipe_enabled: Callable) -> void:
	_fill_contents(contents)
	_fill_recipes(recipes, is_recipe_enabled)
	_show_default_details()
	visible = true


func close() -> void:
	visible = false


func _fill_contents(contents: Dictionary[Item, int]) -> void:
	for slot in _contents_grid.get_children():
		slot.free()
	for item in contents:
		var slot := ITEM_SLOT_SCENE.instantiate()
		_contents_grid.add_child(slot)
		slot.setup(item, contents[item])


func _fill_recipes(recipes: Array[Recipe], is_recipe_enabled: Callable) -> void:
	_recipes = recipes
	_recipe_list.clear()
	for recipe in recipes:
		var index := _recipe_list.add_item(recipe.result.name)
		if not is_recipe_enabled.call(recipe):
			_recipe_list.set_item_disabled(index, true)
			# Explicit color so locked recipes read as greyed out.
			_recipe_list.set_item_custom_fg_color(index, Color(1, 1, 1, 0.3))


func _show_default_details() -> void:
	_details.text = "[color=#9aa4b8]Select a recipe to see its ingredients.[/color]"


func _on_recipe_item_selected(index: int) -> void:
	var recipe := _recipes[index]
	_show_recipe_details(recipe)
	recipe_selected.emit(recipe)


func _show_recipe_details(recipe: Recipe) -> void:
	var lines: PackedStringArray = ["[b]%s[/b]" % recipe.result.name, ""]
	lines.append("[color=#9aa4b8]Ingredients[/color]")
	for ingredient in recipe.incredients:
		lines.append("  • %s" % ingredient.name)
	_details.text = "\n".join(lines)
