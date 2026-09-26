class_name InventorySlot
extends TextureRect

func Setup(item: Item, amount: int) -> void:
	$TextureRect.texture = item.icon
	$Number.text = amount

func reset() -> void:
	$TextureRect.texture = null
	$Number.text = ""
