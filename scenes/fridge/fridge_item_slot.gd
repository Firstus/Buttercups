extends Panel

## Fills the slot with an item and its amount.
## Shows the item name until the item has an icon.
func setup(item: Item, amount: int) -> void:
	$Icon.texture = item.icon
	$Icon.visible = item.icon != null
	$Name.text = item.name
	$Name.visible = item.icon == null
	$Count.text = str(amount)
	tooltip_text = "%s x%d" % [item.name, amount]
