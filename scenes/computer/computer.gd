extends Node2D

const ITEM_DIR := "res://assets/Items"

## Items the computer offers. Every item in ITEM_DIR is offered when left empty.
@export var on_sale: Array[Item] = []
## Node frozen while the shop is open. Falls back to the "player" group when unset.
@export var player: Node

@onready var _menu: ShopMenu = $Menu

var _items: Array[Item] = []
var _player_in_range := false


func _ready() -> void:
	$Label.visible = false
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	_menu.close_requested.connect(_close_menu)
	_menu.item_purchased.connect(_on_item_purchased)
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_load_items()
	# The player can already be standing in the area when this scene loads.
	if _is_player_inside():
		_show_prompt(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_command") and _player_in_range and not _menu.is_open():
		_open_menu()
		get_viewport().set_input_as_handled()


func _open_menu() -> void:
	if _menu.is_open():
		return
	_menu.open(_items, InventorySingleton.money)
	$Label.visible = false
	if player != null:
		player.freeze()


func _close_menu() -> void:
	_menu.close()
	$Label.visible = _player_in_range
	if player != null:
		player.unfreeze()


# TODO: Put the bought items into the inventory/fridge once storage is wired up.
func _on_item_purchased(_item: Item, _amount: int, total: int) -> void:
	InventorySingleton.changeMoney(-total)
	FridgeSingleton.addAmount(_item, _amount)
	_menu.set_money(InventorySingleton.money)


func _load_items() -> void:
	if not on_sale.is_empty():
		_items = on_sale.duplicate()
		_items.sort_custom(_sort_items_by_name)
		return

	var dir := DirAccess.open(ITEM_DIR)
	if dir == null:
		push_warning("Computer: cannot open item folder '%s'" % ITEM_DIR)
		return
	for file_name in dir.get_files():
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue
		var item := load(ITEM_DIR.path_join(file_name)) as Item
		if item != null:
			_items.append(item)
	_items.sort_custom(_sort_items_by_name)


func _sort_items_by_name(a: Item, b: Item) -> bool:
	return a.name.naturalnocasecmp_to(b.name) < 0


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
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _show_prompt(is_visible: bool) -> void:
	$Label.visible = is_visible
