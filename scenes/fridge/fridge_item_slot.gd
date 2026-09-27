extends Button

var buttonItem : Item
var buttonAmount : int
## Fills the slot with an item and its amount.
## Shows the item name until the item has an icon.
func setup(item: Item, amount: int) -> void:
	buttonItem = item
	buttonAmount = amount
	$Icon.texture = item.icon
	$Icon.visible = item.icon != null
	$Name.text = item.name
	$Name.visible = item.icon == null
	$Count.text = str(amount)
	tooltip_text = "%s x%d" % [item.name, amount]
	
func onClick() -> void:
	if buttonAmount <= 0:
		return
	if not FridgeSingleton.removeAmount(buttonItem, 1):
		return
	buttonAmount -= 1
	$Count.text = str(buttonAmount)
	tooltip_text = "%s x%d" % [buttonItem.name, buttonAmount]


func _on_button_up() -> void:
	onClick()
