class_name ShopMenu
extends CanvasLayer

## Emitted when the player buys `amount` of `item` for `total` money.
signal item_purchased(item: Item, amount: int, total: int)
## Emitted when the player closes the shop with Esc.
signal close_requested

const ROW_SCENE := preload("res://scenes/computer/shop_item_row.tscn")
const MIN_AMOUNT := 1
const MAX_AMOUNT := 10
const SUCCESS_COLOR := Color(0.55, 0.85, 0.45)
const ERROR_COLOR := Color(0.92, 0.35, 0.35)

@onready var _scroll: ScrollContainer = $Panel/Margin/VBox/Body/ItemsColumn/Scroll
@onready var _rows: VBoxContainer = $Panel/Margin/VBox/Body/ItemsColumn/Scroll/Rows
@onready var _details: RichTextLabel = $Panel/Margin/VBox/Body/DetailsColumn/Details
@onready var _money_label: Label = $Panel/Margin/VBox/Header/Money
@onready var _status: Label = $Panel/Margin/VBox/Status

var _items: Array[Item] = []
var _row_nodes: Array[ShopItemRow] = []
var _selected_index := 0
var _amount := MIN_AMOUNT
var _money := 0


func _ready() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Shows the shop with `items` and the player's current `money`.
func open(items: Array[Item], money: int) -> void:
	_items = items
	_money = money
	_row_nodes.clear()
	for child in _rows.get_children():
		child.free()
	for item in _items:
		var row: ShopItemRow = ROW_SCENE.instantiate()
		_rows.add_child(row)
		row.setup(item, item.cost)
		_row_nodes.append(row)
	_selected_index = 0
	_amount = MIN_AMOUNT
	_status.text = ""
	_update_money_label()
	visible = true
	_refresh()


func close() -> void:
	visible = false


## Updates the displayed wallet, e.g. after the station deducted a purchase.
func set_money(value: int) -> void:
	_money = value
	_update_money_label()
	_update_details()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return

	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
	elif event.is_action_pressed("action_command"):
		_buy_selected()
	elif event.is_action_pressed("player_up", true):
		_move_selection(-1)
	elif event.is_action_pressed("player_down", true):
		_move_selection(1)
	elif event.is_action_pressed("player_left", true):
		_change_amount(-1)
	elif event.is_action_pressed("player_right", true):
		_change_amount(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _move_selection(step: int) -> void:
	if _items.is_empty():
		return
	_selected_index = wrapi(_selected_index + step, 0, _items.size())
	_amount = MIN_AMOUNT
	_status.text = ""
	_refresh()


func _change_amount(step: int) -> void:
	_amount = clampi(_amount + step, MIN_AMOUNT, MAX_AMOUNT)
	_refresh()


func _buy_selected() -> void:
	if _items.is_empty():
		return
	var item := _items[_selected_index]
	var total := _selected_total()
	if total > _money:
		_show_status("Not enough money.", ERROR_COLOR)
		return
	_show_status("Bought %s x%d for %d" % [item.name, _amount, total], SUCCESS_COLOR)
	item_purchased.emit(item, _amount, total)


func _refresh() -> void:
	for i in _row_nodes.size():
		var row := _row_nodes[i]
		var is_selected := i == _selected_index
		row.set_selected(is_selected)
		if is_selected:
			row.set_amount(_amount)
			_scroll.ensure_control_visible(row)
	_update_details()


func _selected_total() -> int:
	return _items[_selected_index].cost * _amount


func _update_money_label() -> void:
	_money_label.text = "Money %d" % _money


func _update_details() -> void:
	if _items.is_empty():
		_details.text = "[color=#9aa4b8]No ingredients for sale.[/color]"
		return
	var item := _items[_selected_index]
	var total := _selected_total()
	var lines: PackedStringArray = [
		"[b]%s[/b]" % item.name,
		"",
		"[color=#9aa4b8]Unit price[/color]   %d" % item.cost,
		"[color=#9aa4b8]Amount[/color]       %d" % _amount,
	]
	if total > _money:
		lines.append("[color=#9aa4b8]Total[/color]        [color=#ef5350]%d[/color]" % total)
	else:
		lines.append("[color=#9aa4b8]Total[/color]        %d" % total)
	_details.text = "\n".join(lines)


func _show_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
