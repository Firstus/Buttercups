class_name ShopItemRow
extends PanelContainer

const SELECTED_BG_COLOR := Color(0.16, 0.34, 0.44, 0.95)
const SELECTED_BORDER_COLOR := Color(0.45, 0.85, 1, 0.8)
const SELECTED_TEXT_COLOR := Color(0.55, 0.95, 1)
const NORMAL_TEXT_COLOR := Color(0.87, 0.89, 0.93)

@onready var _icon: TextureRect = $Row/Icon
@onready var _name_label: Label = $Row/Name
@onready var _amount_box: HBoxContainer = $Row/AmountBox
@onready var _amount_label: Label = $Row/AmountBox/Amount
@onready var _price_label: Label = $Row/Price

var _normal_style: StyleBox
var _selected_style: StyleBoxFlat


func _ready() -> void:
	_normal_style = get_theme_stylebox("panel")
	_selected_style = _normal_style.duplicate() as StyleBoxFlat
	_selected_style.bg_color = SELECTED_BG_COLOR
	_selected_style.border_color = SELECTED_BORDER_COLOR
	_selected_style.set_border_width_all(1)


## Fills the row with an item and its placeholder unit price.
func setup(item: Item, price: int) -> void:
	_icon.texture = item.icon
	_icon.visible = item.icon != null
	_name_label.text = item.name
	_price_label.text = str(price)


## Highlights the row and reveals its amount selector.
func set_selected(is_selected: bool) -> void:
	add_theme_stylebox_override("panel", _selected_style if is_selected else _normal_style)
	_amount_box.visible = is_selected
	_name_label.add_theme_color_override("font_color", SELECTED_TEXT_COLOR if is_selected else NORMAL_TEXT_COLOR)


func set_amount(amount: int) -> void:
	_amount_label.text = str(amount)
