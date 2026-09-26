class_name ShopMenu
extends CanvasLayer

## Emitted when the player confirms a purchase with Space.
signal item_purchased(item: Item, amount: int)
## Emitted when the player closes the shop with Esc.
signal close_requested

const ROW_SCENE := preload("res://scenes/computer/shop_item_row.tscn")
const MIN_AMOUNT := 1
const MAX_AMOUNT := 10

@onready var _scroll: ScrollContainer = $Panel/Margin/VBox/Body/ItemsColumn/Scroll
@onready var _rows: VBoxContainer = $Panel/Margin/VBox/Body/ItemsColumn/Scroll/Rows
@onready var _details: RichTextLabel = $Panel/Margin/VBox/Body/DetailsColumn/Details
@onready var _status: Label = $Panel/Margin/VBox/Status

var _items: Array[Item] = []
var _prices: Array[int] = []
var _row_nodes: Array[ShopItemRow] = []
var _selected_index := 0
var _amount := MIN_AMOUNT


func _ready() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Shows the shop with `items`; `price_of` is called with each item for its placeholder unit price.
func open(items: Array[Item], price_of: Callable) -> void:
	_items = items
	_prices.clear()
	_row_nodes.clear()
	for child in _rows.get_children():
		child.free()
	for item in _items:
		var price := int(price_of.call(item))
		_prices.append(price)
		var row: ShopItemRow = ROW_SCENE.instantiate()
		_rows.add_child(row)
		row.setup(item, price)
		_row_nodes.append(row)
	_selected_index = 0
	_amount = MIN_AMOUNT
	_status.text = ""
	visible = true
	_refresh()


func close() -> void:
	visible = false


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
	_status.text = "Bought %s x%d" % [item.name, _amount]
	item_purchased.emit(item, _amount)


func _refresh() -> void:
	for i in _row_nodes.size():
		var row := _row_nodes[i]
		var is_selected := i == _selected_index
		row.set_selected(is_selected)
		if is_selected:
			row.set_amount(_amount)
			_scroll.ensure_control_visible(row)
	_update_details()


func _update_details() -> void:
	if _items.is_empty():
		_details.text = "[color=#9aa4b8]No ingredients for sale.[/color]"
		return
	var item := _items[_selected_index]
	var price := _prices[_selected_index]
	var lines: PackedStringArray = [
		"[b]%s[/b]" % item.name,
		"",
		"[color=#9aa4b8]Unit price[/color]   %d" % price,
		"[color=#9aa4b8]Amount[/color]       %d" % _amount,
		"[color=#9aa4b8]Total[/color]        %d" % (price * _amount),
	]
	_details.text = "\n".join(lines)
