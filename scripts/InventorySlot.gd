class_name InventorySlot
extends Panel

func Setup(item: Item, amount: int) -> void:
	$TextureRect.texture = item.icon
	$TextureRect/Number.text = str(amount)

func resetSlot() -> void:
	$TextureRect.texture = null
	$TextureRect/Number.text = ""
