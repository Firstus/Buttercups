extends TextureRect

func Setup(item: Item, amount: int) -> void:
	texture = item.icon
	$Number.text = amount
